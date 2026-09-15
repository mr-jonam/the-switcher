# Appendix — the `--profile` alternative

English | [Italiano](profiles-appendix.it.md)

Lighter than the `CODEX_HOME` standard: no separate folders, no wrapper. In
exchange it does **not** isolate credentials or logs, so it does not help with
cost attribution. Fine if you juggle two projects and only want to swap
model/provider on demand.

## How it works

Codex reads profiles as dedicated files next to the user config. Each profile
points at a custom `model_provider`, and each provider declares **which
environment variable** holds its key (`env_key`). Switching profile switches key.

> Since 0.134.0, `[profiles.<name>]` sections inside `config.toml` are
> deprecated — each profile gets its own `<name>.config.toml` file.

## Steps

**1. Providers — `%USERPROFILE%\.codex\config.toml`**
(merge with your existing config; template: `templates/user-config.toml.template`)

```toml
[model_providers.proj-1]
name     = "Project 1"
base_url = "https://api.openai.com/v1"
env_key  = "OPENAI_API_KEY_PROJ_1"

[model_providers.proj-2]
name     = "Project 2"
base_url = "https://api.openai.com/v1"
env_key  = "OPENAI_API_KEY_PROJ_2"
```

**2. One file per profile — `%USERPROFILE%\.codex\proj-1.config.toml`**
(template: `templates/profile.config.toml.template`)

```toml
model_provider = "proj-1"
```

**3. Keys as Windows user environment variables** (once; restart the terminal)

```powershell
setx OPENAI_API_KEY_PROJ_1 "sk-..."
setx OPENAI_API_KEY_PROJ_2 "sk-..."
```

`setx` writes the key to the user registry **in plaintext**, readable by any
process running as you. That is the trade-off of this approach. Where that
matters, use the `CODEX_HOME` + keyring standard instead.

**4. Usage**

```powershell
codex --profile proj-1
codex exec --profile proj-1 "fix the failing tests"
```

Pair it with shortcuts in your PowerShell profile:

```powershell
function codex-proj-1 { codex --profile proj-1 @args }
function codex-proj-2 { codex --profile proj-2 @args }
```

## Known limits

- A **project-level** `.codex/config.toml` cannot set `profile`,
  `model_provider`, `openai_base_url` or credentials — the choice has to come
  from the command line or a wrapper. So profiles alone can never switch
  automatically per directory.
- History and session logs all stay in one `~/.codex`: `ccusage` cannot tell you
  which key spent what.
- A `CODEX_PROFILE` variable shows up in some recent builds but is not
  documented as stable — don't build a team process on it.

## Can you combine them?

Yes. `CODEX_HOME` isolates credentials; `--profile` varies the model *within* a
project (say a "review" profile with high reasoning effort and a cheaper "quick"
one). The profile files then belong inside that project's `CODEX_HOME`, not in
`~/.codex`.
