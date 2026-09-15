# Changelog

English | [Italiano](CHANGELOG.it.md)

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-15

### Added
- Linux and macOS support through a Bash/Zsh wrapper, a Python 3 resolver and
  an idempotent `install.sh`.
- Unix project-map template and dependency-free resolver/profile tests.
- Ubuntu and macOS CI jobs.
- Complete English and Italian documentation pairs.

### Changed
- PowerShell module version advanced to 1.1.0.
- Credential-store documentation now covers Windows Credential Manager,
  Linux Secret Service keyrings and macOS Keychain.

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
