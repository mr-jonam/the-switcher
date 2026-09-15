# The Switcher

**The right API key, chosen by the folder you're in.**

Codex CLI keeps **one active identity at a time**. Across several projects or
cost centres, repeated logins eventually risk billing tokens to the wrong key.

The Switcher gives each project its own `CODEX_HOME`. A PowerShell wrapper on
Windows or a Bash/Zsh wrapper on Linux and macOS chooses it from the current
directory. You type `codex` exactly as before.

- **No repeated logins**: resolve from `.codexproject` or a local path map.
- **Isolated credentials**: use the OS credential store, keyed per `CODEX_HOME`.
- **Attributable costs**: keep session logs separate for project reports.
- **Reversible**: install in the user profile and remove only its managed block.

[![CI](https://github.com/mr-jonam/the-switcher/actions/workflows/ci.yml/badge.svg)](https://github.com/mr-jonam/the-switcher/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

English | [Italiano](README.it.md)

## Supported platforms

| Platform | Shell | Installer | Credential store |
|---|---|---|---|
| Windows 10/11 | PowerShell 5.1 or 7+ | `install.ps1` | Windows Credential Manager |
| Linux | Bash or Zsh + Python 3.9+ | `install.sh` | desktop Secret Service/keyring |
| macOS | Zsh or Bash + Python 3.9+ | `install.sh` | macOS Keychain |

See the [platform guide](docs/platforms.md) for shell-specific details.

## How it works

`CODEX_HOME` relocates Codex configuration, credentials, history and session
logs. The Switcher resolves a project before launching the real Codex binary:

1. a project pinned for the current shell;
2. a `.codexproject` file found by walking up from the current directory;
3. the longest directory-boundary match in `projects.json`;
4. the configured default project.

The marker contains only an identifier such as `proj-1`. It is safe to commit;
every user still keeps a local mapping and signs in separately.

## Quick start

Requirements: [Codex CLI](https://developers.openai.com/codex/cli), Git, and one
API key for each identity you want to isolate.

### Windows

```powershell
git clone https://github.com/mr-jonam/the-switcher.git
cd the-switcher
powershell -ExecutionPolicy Bypass -File .\install.ps1

# Open a new terminal, edit the dummy mapping, then sign in once.
notepad $HOME\.the-switcher\projects.json
Connect-CodexProject proj-1
Get-CodexProject
```

Uninstall the profile integration with `./install.ps1 -Uninstall`.

### Linux and macOS

```bash
git clone https://github.com/mr-jonam/the-switcher.git
cd the-switcher
bash ./install.sh

# Reload the shell, edit the dummy mapping, then sign in once.
exec "$SHELL" -l
${EDITOR:-vi} "$HOME/.the-switcher/projects.json"
switcher_connect proj-1
switcher_project
```

The installer selects `~/.zshrc` for Zsh and `~/.bashrc` otherwise. Override it
with `--profile PATH`; uninstall with `bash ./install.sh --uninstall`.
Configuration and credentials are preserved.

## Configure dummy projects

The installed map contains only `proj-default`, `proj-1`, `proj-2` and
`proj-3`. Rename them and replace the paths with your own values.

| Field | Value |
|---|---|
| project name | short identifier used by commands and `.codexproject` |
| `description` | optional local description |
| `apiKeyName` | recognisable label, **never the actual API key** |
| `codexHome` | unique state directory for this identity |
| `paths` | absolute project roots; descendants match automatically |

Windows example:

```json
"proj-1": {
  "description": "Example project 1; replace this text",
  "apiKeyName": "KEY_PROJ_1",
  "codexHome": "%USERPROFILE%\\.codex-homes\\proj-1",
  "paths": ["C:\\dev\\proj-1"]
}
```

On Linux/macOS use `${HOME}/.codex-homes/proj-1` and a path such as
`${HOME}/dev/proj-1`. Start from the [Windows template](templates/projects.json)
or [Unix template](templates/projects.unix.json).

To make a repository self-identifying, create this file in its root:

```text
# .codexproject
proj-1
```

Commit only `.codexproject`, never the local map or a credential file.

## Commands

| Purpose | Windows PowerShell | Linux/macOS Bash or Zsh |
|---|---|---|
| run Codex | `codex [args]` | `codex [args]` |
| inspect resolution | `Get-CodexProject` | `switcher_project [path]` |
| pin for this shell | `Use-CodexProject proj-1` / `cxp` | `switcher_use proj-1` / `cxp` |
| store a key | `Connect-CodexProject proj-1` | `switcher_connect proj-1` |
| usage report | `Get-CodexUsage -Period daily` | `switcher_usage daily [proj-1]` |

Shared variables: `SWITCHER_CONFIG`, `SWITCHER_CODEX_EXE`, and
`SWITCHER_QUIET=1`. Unix also supports `SWITCHER_PYTHON` and `SWITCHER_HELPER`.

## Security and cost attribution

- No API key belongs in this repository or in `projects.json`.
- Connect commands mask the key and send it to `codex login --with-api-key`
  through stdin, never as a command-line argument.
- Generated `config.toml` files use `cli_auth_credentials_store = "keyring"`.
- Never commit `auth.json`, `.codex-homes/` or `.the-switcher/`.
- `ccusage` reads isolated sessions. Treat its Codex figures as attribution
  estimates; the platform usage report remains the billing source.

## Documentation

| Guide | English | Italiano |
|---|---|---|
| Platforms and installation | [Read](docs/platforms.md) | [Leggi](docs/platforms.it.md) |
| Profiles appendix | [Read](docs/profiles-appendix.md) | [Leggi](docs/profiles-appendix.it.md) |
| Troubleshooting | [Read](docs/troubleshooting.md) | [Leggi](docs/troubleshooting.it.md) |
| Changelog | [Read](CHANGELOG.md) | [Leggi](CHANGELOG.it.md) |
| License decision | [Read](LICENSE-DECISION.md) | [Leggi](LICENSE-DECISION.it.md) |
| Notice | [Read](NOTICE) | [Leggi](NOTICE.it.md) |

## Development

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser
Invoke-Pester ./tests
```

```bash
bash -n install.sh src/the-switcher.sh tests/test-unix.sh
python3 -m py_compile src/the_switcher_unix.py
bash tests/test-unix.sh
```

CI checks PowerShell on Windows and Unix behavior on Ubuntu and macOS.

## License

MIT. The unchanged English text in [LICENSE](LICENSE) is canonical;
[the Italian note](LICENSE.it.md) is informational only. See the
[license decision](LICENSE-DECISION.md) and [NOTICE](NOTICE).

GitHub topics: `codex-cli`, `openai`, `powershell`, `windows`, `linux`, `macos`,
`developer-tools`, `api-key-management`, `devex`, `cost-governance`, `ccusage`.
