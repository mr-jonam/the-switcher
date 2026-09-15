# The Switcher

**The right API key, chosen by the folder you're in.**

Codex CLI keeps **one active identity at a time**. If you work across several
clients or cost centres with different API keys, that means re-running
`codex login` every time you switch context — and, sooner or later, billing
tokens to the wrong project.

The Switcher gives each project its own `CODEX_HOME` and a PowerShell wrapper
that picks the right one from the directory you're in. You type `codex` exactly
as before; the correct key is selected for you.

- **No manual logins** — the project is resolved from a `.codexproject` file
  in the repo root, or from a path map.
- **Credentials stay isolated** — stored in Windows Credential Manager, keyed
  per `CODEX_HOME`. No plaintext key ever touches disk.
- **Costs become attributable** — session logs are separated per project, so
  `Get-CodexUsage` reports token spend per key instead of one mixed pile.
- **Reversible** — installs into your user profile only; `-Uninstall` removes it.

Setup takes about five minutes. Commit `.codexproject` to a repo and everyone
who clones it gets the right key with zero configuration.

[![CI](https://github.com/mr-jonam/the-switcher/actions/workflows/ci.yml/badge.svg)](https://github.com/mr-jonam/the-switcher/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)](https://learn.microsoft.com/powershell/)

🇮🇹 [Leggi in italiano](README.it.md)

---

## The problem

Codex CLI keeps **one active identity at a time**. Credentials live in
`%USERPROFILE%\.codex` (or in Windows Credential Manager). If you work across
several clients or cost centres with different API keys, you end up:

- re-running `codex login` every time you switch context, or
- using the wrong key and billing tokens to the wrong project, and
- with every session log piled into one folder, so working out which key spent
  what becomes a manual reconciliation job.

A per-project `.codex/config.toml` does not fix this: for security reasons it
cannot override credentials, `model_provider`, `openai_base_url` or `profile` —
those stay user-level settings.

## How it works

`CODEX_HOME` relocates Codex's entire state: `config.toml`, credentials, history
and **session logs**. The Switcher gives each project its own, and a PowerShell
wrapper picks the right one before the real `codex` runs.

```text
C:\dev\proj-1>  codex
[codex] proj-1 | KEY_PROJ_1 | C:\Users\you\.codex-homes\proj-1

C:\dev\proj-2>   codex
[codex] proj-2 | KEY_PROJ_2 | C:\Users\you\.codex-homes\proj-2
```

The project is resolved in this order:

1. an explicit name (`Use-CodexProject proj-1`)
2. a **`.codexproject`** file in the repo root — the lookup walks up the tree
3. the `paths` map in `projects.json` — longest matching prefix wins
4. the `default` project

Step 2 is the one that matters for teams: the file lives in the repo, so anyone
who clones it gets the correct key with zero configuration.

## Install

Requirements: Windows 10/11, PowerShell 5.1 or 7.x, Codex CLI
(`npm i -g @openai/codex`), one API key per project.

```powershell
git clone https://github.com/mr-jonam/the-switcher.git
cd the-switcher
powershell -ExecutionPolicy Bypass -File .\install.ps1

# open a NEW terminal, then
notepad $HOME\.the-switcher\projects.json   # map your projects
Connect-CodexProject proj-1                 # one-off login per key
Get-CodexProject                            # verify
```

The installer is idempotent: re-running it refreshes the module without
duplicating the profile block and without touching your `projects.json`
(use `-Force` to overwrite it). Remove it with `.\install.ps1 -Uninstall`.

## Commands

| Command | What it does |
|---|---|
| `codex` | runs Codex with the current project's `CODEX_HOME` |
| `Get-CodexProject` | resolved project, expected key, how it was resolved, login state |
| `Use-CodexProject <name>` (alias `cxp`) | pins a project for this session |
| `Connect-CodexProject <name>` | API key login into that project's `CODEX_HOME` |
| `Get-CodexUsage -Period daily` | per-project token report via `ccusage` |

Environment variables:

- `SWITCHER_CONFIG` — alternative path to `projects.json`
- `SWITCHER_CODEX_EXE` — explicit path to the `codex` executable
- `SWITCHER_QUIET=1` — hide the `[codex] ...` banner

## Where things live

| File | Destination |
|---|---|
| `src/TheSwitcher.psm1` | `%USERPROFILE%\.the-switcher\TheSwitcher.psm1` |
| `templates/projects.json` | `%USERPROFILE%\.the-switcher\projects.json` |
| `templates/config.toml.template` | `%USERPROFILE%\.codex-homes\<project>\config.toml` |
| `templates/.codexproject` | the **root of your repository** (commit it) |
| profile block | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |

## Configure your projects

After installation, open `%USERPROFILE%\.the-switcher\projects.json`. It
contains only dummy values (`proj-default`, `proj-1`, `proj-2`, `proj-3`):
replace them and their paths with your own project identifiers and folders.

For each project, fill in:

| Field | What to enter |
|---|---|
| project name | a unique short identifier, used by `Use-CodexProject` and `.codexproject` |
| `description` | an optional local label |
| `apiKeyName` | a label for recognizing the key; **not the API key itself** |
| `codexHome` | a unique folder, normally `%USERPROFILE%\\.codex-homes\\<project>` |
| `paths` | absolute paths whose descendants should resolve to this project |

To add another entry, duplicate a `proj-*` block, then adjust every value:

```json
"proj-3": {
  "description": "Example project 3; replace this text",
  "apiKeyName": "KEY_PROJ_3",
  "codexHome": "%USERPROFILE%\\.codex-homes\\proj-3",
  "paths": ["C:\\dev\\proj-3"]
}
```

Then run `Connect-CodexProject proj-3`, and optionally place a `.codexproject`
file containing `proj-3` in that repository's root. Commit only that marker;
each user keeps their own local `projects.json` mapping and signs in separately.

`apiKeyName` is a human-readable label only — it tells you at a glance which key
is in play and ties spend back to your key register. The key value itself never
appears in the file.

## Cost attribution

```powershell
Get-CodexUsage -Period daily                        # every project, one by one
Get-CodexUsage -Project proj-1 -Period monthly
Get-CodexUsage -Period daily -Json                  # feed a tracking workbook
```

It sets `CODEX_HOME` per project and runs `npx ccusage@latest codex <period>`,
which reads `sessions/` and `archived_sessions/`. ccusage's Codex support is
explicitly experimental, so treat the numbers as relative attribution — the
platform usage report remains the billing source of truth.

## Security

- No API keys in this repository, in the templates, or in `projects.json`.
- `Connect-CodexProject` reads the key as masked input and pipes it to
  `codex login --with-api-key` over **stdin** — it never reaches PowerShell
  history or a visible command line.
- Templates set `cli_auth_credentials_store = "keyring"`, so credentials go to
  Windows Credential Manager rather than a plaintext `auth.json`. The keyring
  entry is derived from the `CODEX_HOME` path, so per-project isolation holds
  in keyring mode too.
- Never commit `auth.json` or anything under `.codex-homes\` — both are in
  `.gitignore`. The only file meant to live in a repo is `.codexproject`.

## Docs

- [Profiles appendix](docs/profiles-appendix.md) | [Italiano](docs/profiles-appendix.it.md)
  — the lighter `--profile` alternative, and why it cannot switch automatically
  per directory.
- [Troubleshooting](docs/troubleshooting.md) | [Italiano](docs/troubleshooting.it.md)
  — execution policy, "Access is denied", IDE extension, and friends.

## Development

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser
Invoke-Pester ./tests
```

CI runs the parser on both Windows PowerShell 5.1 and PowerShell 7, validates
the module manifest, runs PSScriptAnalyzer and the Pester suite.

## References

- [Codex advanced configuration](https://developers.openai.com/codex/config-advanced)
- [Codex authentication](https://learn.chatgpt.com/docs/auth)
- [ccusage — Codex guide](https://ccusage.com/guide/codex/)

## License

MIT — see [LICENSE](LICENSE).

## Discoverability

GitHub topics: `codex-cli`, `openai`, `powershell`, `windows`,
`developer-tools`, `api-key-management`, `devex`, `cost-governance`, and
`ccusage`.
