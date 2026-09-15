# Registro delle modifiche

[English](CHANGELOG.md) | Italiano

Qui sono documentate le modifiche rilevanti. Il formato segue
[Keep a Changelog](https://keepachangelog.com/it-IT/1.1.0/) e il progetto usa
[Semantic Versioning](https://semver.org/lang/it/).

## [1.1.0] - 2026-09-15

### Aggiunto
- Supporto Linux e macOS tramite wrapper Bash/Zsh, resolver Python 3 e
  `install.sh` idempotente.
- Template Unix e test senza dipendenze per risoluzione e profilo.
- Job CI per Ubuntu e macOS.
- Coppie complete della documentazione in inglese e italiano.

### Modificato
- Versione del modulo PowerShell aggiornata a 1.1.0.
- Documentazione del credential store estesa a Windows Credential Manager,
  Secret Service su Linux e Portachiavi macOS.

## [1.0.0] - 2026-09-15

### Aggiunto
- Wrapper `codex` con `CODEX_HOME` risolto dalla directory corrente.
- Risoluzione in quattro passaggi: nome esplicito, marker `.codexproject`,
  mappa dei percorsi e progetto predefinito.
- Login API key via stdin, controllo dello stato e report con `ccusage`.
- Installer PowerShell idempotente, template, test Pester e CI Windows.
