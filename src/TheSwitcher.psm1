<#
    The Switcher - per-project OpenAI API key switching for Codex CLI on Windows.

    Each project gets its own CODEX_HOME, which means its own credentials,
    its own config.toml and its own session logs. The `codex` wrapper resolves
    the project from the current directory and points CODEX_HOME at it before
    invoking the real executable.

    Installed to: %USERPROFILE%\.the-switcher\TheSwitcher.psm1
    Loaded from the PowerShell profile by install.ps1.
#>

$script:DefaultConfigPath = Join-Path $HOME '.the-switcher\projects.json'
$script:MarkerFileName    = '.codexproject'

# ------------------------------------------------------------------ helpers

function Expand-SwitcherPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if ($expanded -like '~*') { $expanded = Join-Path $HOME $expanded.Substring(1).TrimStart('\', '/') }
    return $expanded
}

function Get-SwitcherConfigPath {
    if ($env:SWITCHER_CONFIG) { return (Expand-SwitcherPath $env:SWITCHER_CONFIG) }
    return $script:DefaultConfigPath
}

function Get-SwitcherConfig {
    <#
    .SYNOPSIS
        Reads the project map (projects.json).
    #>
    [CmdletBinding()]
    param([string]$Path)

    if (-not $Path) { $Path = Get-SwitcherConfigPath }
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Project map not found: $Path`nRun install.ps1 or set `$env:SWITCHER_CONFIG."
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    try { return ($raw | ConvertFrom-Json) }
    catch { throw "Invalid JSON in $Path : $($_.Exception.Message)" }
}

function Get-CodexExecutable {
    <#
    .SYNOPSIS
        Path to the real codex executable (not this module's alias).
    #>
    [CmdletBinding()]
    param()

    if ($env:SWITCHER_CODEX_EXE -and (Test-Path -LiteralPath $env:SWITCHER_CODEX_EXE)) { return $env:SWITCHER_CODEX_EXE }

    $cmd = Get-Command -Name 'codex' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) {
        throw "Executable 'codex' not found on PATH. Install Codex CLI (npm i -g @openai/codex) or set `$env:SWITCHER_CODEX_EXE."
    }
    return $cmd.Source
}

function Find-CodexProjectMarker {
    <#
    .SYNOPSIS
        Walks up the directory tree looking for a .codexproject marker file.
    #>
    [CmdletBinding()]
    param([string]$StartPath = (Get-Location).Path)

    $dir = $null
    try { $dir = Get-Item -LiteralPath $StartPath -ErrorAction Stop } catch { return $null }
    if ($dir.PSIsContainer -eq $false) { $dir = $dir.Directory }

    while ($null -ne $dir) {
        $marker = Join-Path $dir.FullName $script:MarkerFileName
        if (Test-Path -LiteralPath $marker) {
            $line = Get-Content -LiteralPath $marker -ErrorAction SilentlyContinue |
                    Where-Object { $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#') } |
                    Select-Object -First 1
            if ($line) { return $line.Trim() }
        }
        $dir = $dir.Parent
    }
    return $null
}

function Get-CodexProjectNames {
    <#
    .SYNOPSIS
        Lists the project names defined in the project map.
    #>
    [CmdletBinding()]
    param()
    $cfg = Get-SwitcherConfig
    return $cfg.projects.PSObject.Properties.Name
}

# ------------------------------------------------------------------ core

function Resolve-CodexProject {
    <#
    .SYNOPSIS
        Decides which project - and therefore which CODEX_HOME and API key - applies.
    .DESCRIPTION
        Precedence:
          1. explicit -Name
          2. a .codexproject file in the current directory or any parent
          3. the "paths" map in projects.json (longest matching prefix wins)
          4. the "default" project
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Path = (Get-Location).Path
    )

    $cfg      = Get-SwitcherConfig
    $projects = $cfg.projects
    $source   = 'parameter'

    if (-not $Name) {
        $Name = Find-CodexProjectMarker -StartPath $Path
        if ($Name) { $source = "$($script:MarkerFileName) file" }
    }

    if (-not $Name) {
        $best = $null; $bestLen = -1
        $currentPath = $Path.TrimEnd('\', '/')
        foreach ($prop in $projects.PSObject.Properties) {
            $entry = $prop.Value
            $roots = @()
            if ($entry.PSObject.Properties['paths']) { $roots = @($entry.paths) }
            foreach ($root in $roots) {
                $r = Expand-SwitcherPath $root
                if (-not $r) { continue }
                $r = $r.TrimEnd('\', '/')
                $isMatch = $currentPath.Equals($r, [System.StringComparison]::OrdinalIgnoreCase) -or
                    ($currentPath.Length -gt $r.Length -and
                     $currentPath.StartsWith($r, [System.StringComparison]::OrdinalIgnoreCase) -and
                     ($currentPath[$r.Length] -eq '\' -or $currentPath[$r.Length] -eq '/'))
                if ($isMatch -and $r.Length -gt $bestLen) {
                    $best = $prop.Name; $bestLen = $r.Length
                }
            }
        }
        if ($best) { $Name = $best; $source = 'path map' }
    }

    if (-not $Name) {
        if ($cfg.PSObject.Properties['default']) { $Name = $cfg.default; $source = 'default' }
    }

    if (-not $Name) { throw "No project resolved and no 'default' defined in $(Get-SwitcherConfigPath)." }

    if (-not $projects.PSObject.Properties[$Name]) {
        throw "Project '$Name' is not defined in $(Get-SwitcherConfigPath). Available: $((Get-CodexProjectNames) -join ', ')"
    }

    $entry     = $projects.$Name
    $codexHome = $null
    if ($entry.PSObject.Properties['codexHome']) { $codexHome = Expand-SwitcherPath $entry.codexHome }
    if (-not $codexHome) { $codexHome = Join-Path $HOME ".codex-homes\$Name" }

    [pscustomobject]@{
        Name        = $Name
        CodexHome   = $codexHome
        ApiKeyName  = $(if ($entry.PSObject.Properties['apiKeyName']) { $entry.apiKeyName } else { '(unnamed)' })
        Description = $(if ($entry.PSObject.Properties['description']) { $entry.description } else { '' })
        Source      = $source
    }
}

function Use-CodexProject {
    <#
    .SYNOPSIS
        Pins a project for the current shell session.
    .EXAMPLE
        Use-CodexProject proj-1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string]$Name,
        [switch]$Quiet
    )

    $p = Resolve-CodexProject -Name $Name
    if (-not (Test-Path -LiteralPath $p.CodexHome)) {
        New-Item -ItemType Directory -Force -Path $p.CodexHome | Out-Null
    }
    $env:CODEX_HOME = $p.CodexHome
    if (-not $Quiet) {
        Write-Host "[codex] project: $($p.Name)  |  key: $($p.ApiKeyName)  |  home: $($p.CodexHome)" -ForegroundColor Cyan
    }
    return $p
}

function Get-CodexProject {
    <#
    .SYNOPSIS
        Shows which project would be used right now, and whether it is logged in.
    #>
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path)

    $p        = Resolve-CodexProject -Path $Path
    $authFile = Join-Path $p.CodexHome 'auth.json'
    $cfgFile  = Join-Path $p.CodexHome 'config.toml'

    [pscustomobject]@{
        Project     = $p.Name
        Description = $p.Description
        ApiKey      = $p.ApiKeyName
        CodexHome   = $p.CodexHome
        ResolvedBy  = $p.Source
        ConfigToml  = (Test-Path -LiteralPath $cfgFile)
        AuthJson    = (Test-Path -LiteralPath $authFile)
    }
}

function Connect-CodexProject {
    <#
    .SYNOPSIS
        Logs in with an API key inside a project's CODEX_HOME.
    .DESCRIPTION
        The key is read as masked input and handed to Codex over stdin, so it
        never lands in PowerShell history or in a visible command line.
    .EXAMPLE
        Connect-CodexProject proj-1
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Name)

    $p   = Use-CodexProject -Name $Name -Quiet
    $exe = Get-CodexExecutable
    New-Item -ItemType Directory -Force -Path $p.CodexHome | Out-Null

    Write-Host "Login for project '$($p.Name)' (expected key: $($p.ApiKeyName))" -ForegroundColor Cyan
    Write-Host "CODEX_HOME = $($p.CodexHome)" -ForegroundColor DarkGray
    $secure = Read-Host -Prompt 'Paste the API key' -AsSecureString
    if (-not $secure -or $secure.Length -eq 0) { Write-Warning 'No key entered - aborted.'; return }

    $bstr  = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    try {
        $plain | & $exe login --with-api-key
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Login failed (exit $LASTEXITCODE). On older Codex CLI builds try: `$env:CODEX_HOME='$($p.CodexHome)'; codex login"
        } else {
            Write-Host "OK - credentials stored for $($p.CodexHome)" -ForegroundColor Green
        }
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        $plain = $null
        [GC]::Collect()
    }
}

function Get-CodexUsage {
    <#
    .SYNOPSIS
        Per-project token report, reading each CODEX_HOME's logs with ccusage.
    .EXAMPLE
        Get-CodexUsage -Period daily
        Get-CodexUsage -Project proj-1 -Period monthly
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('daily', 'monthly', 'session')][string]$Period = 'daily',
        [string[]]$Project,
        [switch]$Json
    )

    $names = if ($Project) { $Project } else { Get-CodexProjectNames }
    $saved = $env:CODEX_HOME
    try {
        foreach ($n in $names) {
            $p = Resolve-CodexProject -Name $n
            if (-not (Test-Path -LiteralPath (Join-Path $p.CodexHome 'sessions'))) {
                Write-Host "[$n] no session logs in $($p.CodexHome) - skipped." -ForegroundColor DarkGray
                continue
            }
            Write-Host "`n=== $n  ($($p.ApiKeyName)) ===" -ForegroundColor Cyan
            $env:CODEX_HOME = $p.CodexHome
            if ($Json) { npx -y ccusage@latest codex $Period --json }
            else       { npx -y ccusage@latest codex $Period }
        }
    }
    finally { $env:CODEX_HOME = $saved }
}

# ------------------------------------------------------------------ wrapper

function Invoke-CodexWithProject {
    <#
    .SYNOPSIS
        'codex' wrapper: resolves the project from the current directory, then runs the real executable.
    #>
    $p = Resolve-CodexProject
    $env:CODEX_HOME = $p.CodexHome

    if (-not (Test-Path -LiteralPath $p.CodexHome)) {
        New-Item -ItemType Directory -Force -Path $p.CodexHome | Out-Null
    }
    if ($env:SWITCHER_QUIET -ne '1') {
        Write-Host "[codex] $($p.Name) | $($p.ApiKeyName) | $($p.CodexHome)" -ForegroundColor DarkGray
    }

    $exe = Get-CodexExecutable
    & $exe @args
}

Set-Alias -Name codex -Value Invoke-CodexWithProject -Scope Global -Force
Set-Alias -Name cxp   -Value Use-CodexProject        -Scope Global -Force

Export-ModuleMember `
    -Function Get-SwitcherConfig, Get-CodexExecutable, Find-CodexProjectMarker, Get-CodexProjectNames,
              Resolve-CodexProject, Use-CodexProject, Get-CodexProject, Connect-CodexProject,
              Get-CodexUsage, Invoke-CodexWithProject `
    -Alias codex, cxp
