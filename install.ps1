<#
.SYNOPSIS
    Installs The Switcher for the current user.

.DESCRIPTION
    - copies the module to %USERPROFILE%\.the-switcher
    - creates projects.json from the template (if absent)
    - creates one CODEX_HOME per project, each with its own config.toml
    - adds a delimited block to the user's PowerShell profile

    Nothing outside the user profile is touched, and no API key is ever written to disk.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $HOME '.the-switcher'),
    [string]$HomesRoot   = (Join-Path $HOME '.codex-homes'),
    [switch]$Force,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$repoRoot    = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleSrc   = Join-Path (Join-Path $repoRoot 'src') 'TheSwitcher.psm1'
$manifestSrc = Join-Path (Join-Path $repoRoot 'src') 'TheSwitcher.psd1'
$projectsTpl = Join-Path (Join-Path $repoRoot 'templates') 'projects.json'
$configTpl   = Join-Path (Join-Path $repoRoot 'templates') 'config.toml.template'
$beginMarker = '# >>> the-switcher >>>'
$endMarker   = '# <<< the-switcher <<<'

function Write-Step { param($Text); Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Ok   { param($Text); Write-Host "    $Text" -ForegroundColor Green }
function Write-Skip { param($Text); Write-Host "    $Text" -ForegroundColor DarkGray }

function Edit-ProfileBlock {
    param([string]$ProfilePath, [string]$Block, [switch]$Remove)

    $dir = Split-Path -Parent $ProfilePath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if (-not (Test-Path -LiteralPath $ProfilePath)) { New-Item -ItemType File -Force -Path $ProfilePath | Out-Null }

    $content = Get-Content -LiteralPath $ProfilePath -Raw -Encoding UTF8
    if ($null -eq $content) { $content = '' }

    $pattern = [regex]::Escape($beginMarker) + '[\s\S]*?' + [regex]::Escape($endMarker)
    $content = [regex]::Replace($content, $pattern, '')
    $content = $content.TrimEnd()

    if (-not $Remove) {
        if ($content) { $content += "`r`n`r`n" }
        $content += $Block
    }
    Set-Content -LiteralPath $ProfilePath -Value ($content.TrimEnd() + "`r`n") -Encoding UTF8
}

# ------------------------------------------------------------------ uninstall
if ($Uninstall) {
    Write-Step "Removing the block from $PROFILE"
    Edit-ProfileBlock -ProfilePath $PROFILE -Block '' -Remove
    Write-Ok 'Block removed. CODEX_HOME folders and projects.json were left untouched.'
    Write-Host "To remove the data too: Remove-Item -Recurse '$InstallRoot', '$HomesRoot'" -ForegroundColor DarkGray
    return
}

# ------------------------------------------------------------------ install
Write-Step "Installing into $InstallRoot"
New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
Copy-Item -LiteralPath $moduleSrc -Destination (Join-Path $InstallRoot 'TheSwitcher.psm1') -Force
if (Test-Path -LiteralPath $manifestSrc) {
    Copy-Item -LiteralPath $manifestSrc -Destination (Join-Path $InstallRoot 'TheSwitcher.psd1') -Force
}
Write-Ok 'Module copied.'

$projectsPath = Join-Path $InstallRoot 'projects.json'
if ((Test-Path -LiteralPath $projectsPath) -and -not $Force) {
    Write-Skip 'projects.json already exists - left untouched (use -Force to overwrite).'
} else {
    Copy-Item -LiteralPath $projectsTpl -Destination $projectsPath -Force
    Write-Ok "projects.json created from template: $projectsPath"
}

Write-Step 'Creating one CODEX_HOME per project'
$cfg = Get-Content -LiteralPath $projectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$tplContent = Get-Content -LiteralPath $configTpl -Raw -Encoding UTF8

foreach ($prop in $cfg.projects.PSObject.Properties) {
    $name  = $prop.Name
    $entry = $prop.Value

    $homePath = $null
    if ($entry.PSObject.Properties['codexHome']) { $homePath = [Environment]::ExpandEnvironmentVariables($entry.codexHome) }
    if (-not $homePath) { $homePath = Join-Path $HomesRoot $name }

    New-Item -ItemType Directory -Force -Path $homePath | Out-Null

    $target = Join-Path $homePath 'config.toml'
    if (Test-Path -LiteralPath $target) {
        Write-Skip "$name : config.toml already present."
    } else {
        $keyName = if ($entry.PSObject.Properties['apiKeyName']) { $entry.apiKeyName } else { 'UNDEFINED' }
        $desc    = if ($entry.PSObject.Properties['description']) { $entry.description } else { '' }
        $out = $tplContent.Replace('{{PROJECT_NAME}}', $name).Replace('{{API_KEY_NAME}}', $keyName).Replace('{{DESCRIPTION}}', $desc)
        Set-Content -LiteralPath $target -Value $out -Encoding UTF8
        Write-Ok "$name : $homePath"
    }
}

Write-Step "Updating the PowerShell profile: $PROFILE"
$block = @"
$beginMarker
`$env:SWITCHER_CONFIG = '$projectsPath'
Import-Module '$(Join-Path $InstallRoot 'TheSwitcher.psm1')' -DisableNameChecking -Global
$endMarker
"@
Edit-ProfileBlock -ProfilePath $PROFILE -Block $block
Write-Ok 'Profile updated (delimited block, safe to re-run).'

Write-Host ''
Write-Step 'Done. Next steps'
Write-Host @"
  1. Open a NEW PowerShell window (or run: . `$PROFILE)
  2. Edit the project map:       notepad $projectsPath
  3. Log in once per project:    Connect-CodexProject <project-name>
  4. Check where you are:        Get-CodexProject
  5. Optional, per repo:         add a .codexproject file with the project name
  6. Per-project token report:   Get-CodexUsage -Period daily
"@ -ForegroundColor Gray
