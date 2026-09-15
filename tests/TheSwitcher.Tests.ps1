#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
    $script:ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'src/TheSwitcher.psm1'
    $script:Sandbox    = Join-Path ([System.IO.Path]::GetTempPath()) ("switcher-tests-" + [guid]::NewGuid().ToString('N'))

    $repoA  = Join-Path $script:Sandbox 'repoA/sub'
    $repoB  = Join-Path $script:Sandbox 'repoB/deep/er'
    $elsewhere = Join-Path $script:Sandbox 'elsewhere'
    New-Item -ItemType Directory -Force -Path $repoA, $repoB, $elsewhere | Out-Null
    Set-Content -Path (Join-Path $script:Sandbox 'repoB/.codexproject') -Value "# comment`nproj-2"

    $cfg = [ordered]@{
        default  = 'proj-default'
        projects = [ordered]@{
            'proj-default' = @{ description = 'fallback'; apiKeyName = 'none';  codexHome = (Join-Path $script:Sandbox 'homes/default') }
            'proj-1' = @{ description = 'project 1'; apiKeyName = 'KEY_1'; codexHome = (Join-Path $script:Sandbox 'homes/proj-1'); paths = @((Join-Path $script:Sandbox 'repoA')) }
            'proj-2' = @{ description = 'project 2'; apiKeyName = 'KEY_2'; codexHome = (Join-Path $script:Sandbox 'homes/proj-2'); paths = @() }
        }
    }
    $script:ConfigPath = Join-Path $script:Sandbox 'projects.json'
    $cfg | ConvertTo-Json -Depth 6 | Set-Content -Path $script:ConfigPath -Encoding UTF8

    $env:SWITCHER_CONFIG = $script:ConfigPath
    Import-Module $script:ModulePath -Force -DisableNameChecking

    $script:RepoA = $repoA; $script:RepoB = $repoB; $script:Elsewhere = $elsewhere
}

AfterAll {
    Remove-Module TheSwitcher -Force -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $script:Sandbox -ErrorAction SilentlyContinue
    $env:SWITCHER_CONFIG = $null
}

Describe 'Resolve-CodexProject' {

    It 'resolves from the path map' {
        Push-Location $script:RepoA
        try {
            $p = Resolve-CodexProject
            $p.Name       | Should -Be 'proj-1'
            $p.Source     | Should -Be 'path map'
            $p.ApiKeyName | Should -Be 'KEY_1'
        } finally { Pop-Location }
    }

    It 'does not match a path-map prefix in an unrelated sibling directory' {
        $sibling = Join-Path $script:Sandbox 'repoA-unrelated'
        New-Item -ItemType Directory -Force -Path $sibling | Out-Null
        Push-Location $sibling
        try {
            (Resolve-CodexProject).Name | Should -Be 'proj-default'
        } finally { Pop-Location }
    }

    It 'resolves from a .codexproject marker in a parent directory' {
        Push-Location $script:RepoB
        try {
            $p = Resolve-CodexProject
            $p.Name   | Should -Be 'proj-2'
            $p.Source | Should -Be '.codexproject file'
        } finally { Pop-Location }
    }

    It 'falls back to the default project' {
        Push-Location $script:Elsewhere
        try {
            (Resolve-CodexProject).Name | Should -Be 'proj-default'
        } finally { Pop-Location }
    }

    It 'honours an explicit -Name over the current directory' {
        Push-Location $script:RepoA
        try {
            (Resolve-CodexProject -Name 'proj-2').Name | Should -Be 'proj-2'
        } finally { Pop-Location }
    }

    It 'throws for an unknown project' {
        { Resolve-CodexProject -Name 'does-not-exist' } | Should -Throw '*not defined*'
    }
}

Describe 'Get-CodexProjectNames' {
    It 'lists every project in the map' {
        Get-CodexProjectNames | Should -Contain 'proj-1'
        (Get-CodexProjectNames).Count | Should -Be 3
    }
}

Describe 'Use-CodexProject' {
    It 'sets CODEX_HOME and creates the directory' {
        $p = Use-CodexProject -Name 'proj-1' -Quiet
        $env:CODEX_HOME | Should -Be $p.CodexHome
        Test-Path $p.CodexHome | Should -BeTrue
    }
}

Describe 'Get-SwitcherConfig' {
    It 'throws a helpful error when the map is missing' {
        { Get-SwitcherConfig -Path (Join-Path $script:Sandbox 'nope.json') } | Should -Throw '*Project map not found*'
    }
}
