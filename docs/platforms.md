# Platforms and installation

English | [Italiano](platforms.it.md)

## Windows

Use Windows 10/11 with Windows PowerShell 5.1 or PowerShell 7+. Run
`powershell -ExecutionPolicy Bypass -File .\install.ps1`, open a new terminal,
edit `%USERPROFILE%\.the-switcher\projects.json`, then run
`Connect-CodexProject proj-1`.

Re-running the installer updates the module without duplicating its profile
block. `-Force` replaces the local dummy map; `-Uninstall` removes only the
managed integration.

## Linux

Install Python 3.9+ and use Bash or Zsh. A graphical Secret Service-compatible
keyring must be available when Codex stores credentials in `keyring` mode.

```bash
bash ./install.sh
exec "$SHELL" -l
${EDITOR:-vi} "$HOME/.the-switcher/projects.json"
switcher_connect proj-1
```

Headless systems may not expose an unlocked desktop keyring. Verify Codex
authentication before relying on that environment; do not use a plaintext
credential file on a shared host.

## macOS

Python 3.9+ and Zsh or Bash are required. Zsh is detected from `$SHELL`, so the
default profile is `~/.zshrc`. Codex `keyring` storage uses the system Keychain.

```bash
bash ./install.sh
exec "$SHELL" -l
switcher_connect proj-1
```

## Installer options

```text
./install.sh --force              replace the dummy projects.json
./install.sh --profile PATH       manage a specific Bash/Zsh profile
./install.sh --uninstall          remove the managed profile block
```

Uninstall preserves `~/.the-switcher`, `CODEX_HOME` directories and credential
entries. Remove those separately only after verifying their exact paths.

## Shell lifecycle

The Unix integration is sourced, so reload the profile after installing.
`switcher_use proj-1` affects only the current shell and child processes.

```bash
unset SWITCHER_PROJECT  # return to directory-based resolution
switcher_project
```

Use `SWITCHER_CONFIG`, `SWITCHER_CODEX_EXE`, `SWITCHER_PYTHON` or
`SWITCHER_HELPER` only when the defaults do not fit your installation.
