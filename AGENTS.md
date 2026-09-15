# Project map

- Stack: PowerShell 5.1+/7+ on Windows; Bash/Zsh with Python 3.9+ on Linux and macOS.
- Entrypoints: `install.ps1` installs the PowerShell module; `install.sh` installs `src/the-switcher.sh` and its Python resolver.
- Configuration templates: `templates/`; never add credentials, `auth.json`, or `.codex-homes/` content.
- Tests: `tests/TheSwitcher.Tests.ps1` and `tests/test-unix.sh`; CI runs on Windows, Ubuntu and macOS.
- Local verification: `Invoke-Pester ./tests`; on Unix run `bash tests/test-unix.sh`.
- Formatting: CRLF for PowerShell, LF for shell/Python; use clear, security-focused English messages.
- Documentation: English is primary (`README.md`, `docs/*.md`); Italian translations use the `.it.md` suffix.
- Release metadata: keep `LICENSE`, `NOTICE`, `LICENSE-DECISION.md`, and `.provenance/manifest.json` aligned with the published content.
