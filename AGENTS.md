# Project map

- Stack: PowerShell module (Windows PowerShell 5.1+ and PowerShell 7+).
- Entrypoints: `install.ps1` installs `src/TheSwitcher.psm1`; `src/TheSwitcher.psd1` is the module manifest.
- Configuration templates: `templates/`; never add credentials, `auth.json`, or `.codex-homes/` content.
- Tests: `tests/TheSwitcher.Tests.ps1`; CI is `.github/workflows/ci.yml` on Windows.
- Local verification: `Invoke-Pester ./tests` after installing Pester 5.5+.
- Formatting: preserve CRLF for PowerShell files and use clear, security-focused English messages.
- Documentation: English is primary (`README.md`, `docs/*.md`); Italian translations use the `.it.md` suffix.
- Release metadata: keep `LICENSE`, `NOTICE`, `LICENSE-DECISION.md`, and `.provenance/manifest.json` aligned with the published content.
