# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-15

### Added
- `codex` wrapper that resolves the active project from the current directory
  and points `CODEX_HOME` at it before invoking the real executable.
- Four-step project resolution: explicit name, `.codexproject` marker file,
  path map, default project.
- `Connect-CodexProject` — API key login over stdin, into the project's own
  `CODEX_HOME`, with credentials in Windows Credential Manager.
- `Get-CodexProject` — shows the resolved project, expected key and login state.
- `Get-CodexUsage` — per-project token reporting via `ccusage`.
- `install.ps1` — idempotent installer with `-Force` and `-Uninstall`.
- Templates for `projects.json`, per-project `config.toml`, `.codexproject`,
  and the alternative profile-based setup.
- Pester test suite and a CI workflow running on Windows PowerShell 5.1 and 7.x.
