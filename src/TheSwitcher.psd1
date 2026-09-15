@{
    RootModule        = 'TheSwitcher.psm1'
    ModuleVersion     = '1.1.0'
    GUID              = 'd4701076-e68a-441a-a4a2-d95ac322f710'
    Author            = 'mr-jonam'
    Description       = 'Per-project OpenAI API key switching for Codex CLI on Windows. One CODEX_HOME per project, resolved from the current directory.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-SwitcherConfig', 'Get-CodexExecutable', 'Find-CodexProjectMarker', 'Get-CodexProjectNames',
        'Resolve-CodexProject', 'Use-CodexProject', 'Get-CodexProject', 'Connect-CodexProject',
        'Get-CodexUsage', 'Invoke-CodexWithProject'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @('codex', 'cxp')
    PrivateData = @{
        PSData = @{
            Tags       = @('codex', 'openai', 'api-key', 'windows', 'developer-tools')
            LicenseUri = 'https://github.com/mr-jonam/the-switcher/blob/main/LICENSE'
            ProjectUri = 'https://github.com/mr-jonam/the-switcher'
        }
    }
}
