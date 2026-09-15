# The Switcher

**La chiave API giusta, scelta dalla cartella in cui sei.**

Codex CLI mantiene **una sola identità attiva per volta**. Lavorando su più
progetti o centri di costo, i login ripetuti rischiano prima o poi di imputare
token alla chiave sbagliata.

The Switcher assegna a ogni progetto un `CODEX_HOME`. Un wrapper PowerShell su
Windows o Bash/Zsh su Linux e macOS lo sceglie dalla directory corrente.
Continui a digitare `codex` esattamente come prima.

- **Niente login ripetuti**: risoluzione da `.codexproject` o mappa locale.
- **Credenziali isolate**: archivio del sistema operativo, distinto per `CODEX_HOME`.
- **Costi attribuibili**: log separati per report per progetto.
- **Reversibile**: installazione nel profilo utente e rimozione del solo blocco gestito.

[![CI](https://github.com/mr-jonam/the-switcher/actions/workflows/ci.yml/badge.svg)](https://github.com/mr-jonam/the-switcher/actions/workflows/ci.yml)
[![Licenza: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.md) | Italiano

## Piattaforme supportate

| Piattaforma | Shell | Installer | Archivio credenziali |
|---|---|---|---|
| Windows 10/11 | PowerShell 5.1 o 7+ | `install.ps1` | Windows Credential Manager |
| Linux | Bash o Zsh + Python 3.9+ | `install.sh` | Secret Service/keyring desktop |
| macOS | Zsh o Bash + Python 3.9+ | `install.sh` | Portachiavi macOS |

Consulta la [guida alle piattaforme](docs/platforms.it.md) per i dettagli delle shell.

## Come funziona

`CODEX_HOME` sposta configurazione, credenziali, cronologia e log di sessione di
Codex. The Switcher risolve il progetto prima di lanciare il vero binario Codex:

1. progetto forzato nella shell corrente;
2. file `.codexproject` trovato risalendo dalla directory corrente;
3. corrispondenza più lunga, sul confine della directory, in `projects.json`;
4. progetto predefinito configurato.

Il marker contiene solo un identificativo come `proj-1` ed è committabile. Ogni
utente mantiene comunque la propria mappa locale ed esegue il login separatamente.

## Avvio rapido

Requisiti: [Codex CLI](https://developers.openai.com/codex/cli), Git e una API key
per ogni identità che vuoi isolare.

### Windows

```powershell
git clone https://github.com/mr-jonam/the-switcher.git
cd the-switcher
powershell -ExecutionPolicy Bypass -File .\install.ps1

# Apri un nuovo terminale, modifica la mappa fittizia ed esegui il login.
notepad $HOME\.the-switcher\projects.json
Connect-CodexProject proj-1
Get-CodexProject
```

Disinstalla l’integrazione del profilo con `./install.ps1 -Uninstall`.

### Linux e macOS

```bash
git clone https://github.com/mr-jonam/the-switcher.git
cd the-switcher
bash ./install.sh

# Ricarica la shell, modifica la mappa fittizia ed esegui il login.
exec "$SHELL" -l
${EDITOR:-vi} "$HOME/.the-switcher/projects.json"
switcher_connect proj-1
switcher_project
```

L’installer sceglie `~/.zshrc` per Zsh e `~/.bashrc` negli altri casi. Puoi
indicare `--profile PERCORSO`; disinstalla con `bash ./install.sh --uninstall`.
Configurazione e credenziali vengono conservate.

## Configurare i progetti fittizi

La mappa installata contiene soltanto `proj-default`, `proj-1`, `proj-2` e
`proj-3`. Rinominali e sostituisci i percorsi con i tuoi valori.

| Campo | Valore |
|---|---|
| nome progetto | identificativo breve usato dai comandi e da `.codexproject` |
| `description` | descrizione locale facoltativa |
| `apiKeyName` | etichetta riconoscibile, **mai la vera API key** |
| `codexHome` | directory di stato univoca per questa identità |
| `paths` | root assolute; le sottocartelle corrispondono automaticamente |

Esempio Windows:

```json
"proj-1": {
  "description": "Progetto di esempio 1; sostituisci questo testo",
  "apiKeyName": "KEY_PROJ_1",
  "codexHome": "%USERPROFILE%\\.codex-homes\\proj-1",
  "paths": ["C:\\dev\\proj-1"]
}
```

Su Linux/macOS usa `${HOME}/.codex-homes/proj-1` e un percorso come
`${HOME}/dev/proj-1`. Parti dal [template Windows](templates/projects.json) o
dal [template Unix](templates/projects.unix.json).

Per rendere un repository auto-identificabile, crea nella sua root:

```text
# .codexproject
proj-1
```

Committa soltanto `.codexproject`, mai la mappa locale o un file di credenziali.

## Comandi

| Scopo | Windows PowerShell | Linux/macOS Bash o Zsh |
|---|---|---|
| eseguire Codex | `codex [argomenti]` | `codex [argomenti]` |
| verificare la risoluzione | `Get-CodexProject` | `switcher_project [percorso]` |
| forzare nella shell | `Use-CodexProject proj-1` / `cxp` | `switcher_use proj-1` / `cxp` |
| memorizzare una chiave | `Connect-CodexProject proj-1` | `switcher_connect proj-1` |
| report di utilizzo | `Get-CodexUsage -Period daily` | `switcher_usage daily [proj-1]` |

Variabili condivise: `SWITCHER_CONFIG`, `SWITCHER_CODEX_EXE` e
`SWITCHER_QUIET=1`. Unix supporta anche `SWITCHER_PYTHON` e `SWITCHER_HELPER`.

## Sicurezza e attribuzione dei costi

- Nessuna API key deve stare nel repository o in `projects.json`.
- I comandi di connessione mascherano la chiave e la inviano a
  `codex login --with-api-key` via stdin, mai come argomento della riga di comando.
- I `config.toml` generati usano `cli_auth_credentials_store = "keyring"`.
- Non committare mai `auth.json`, `.codex-homes/` o `.the-switcher/`.
- `ccusage` legge le sessioni isolate. Considera i dati Codex come stime di
  attribuzione; il report della piattaforma resta la fonte di fatturazione.

## Documentazione

| Guida | English | Italiano |
|---|---|---|
| Piattaforme e installazione | [Read](docs/platforms.md) | [Leggi](docs/platforms.it.md) |
| Appendice profili | [Read](docs/profiles-appendix.md) | [Leggi](docs/profiles-appendix.it.md) |
| Risoluzione dei problemi | [Read](docs/troubleshooting.md) | [Leggi](docs/troubleshooting.it.md) |
| Changelog | [Read](CHANGELOG.md) | [Leggi](CHANGELOG.it.md) |
| Scelta della licenza | [Read](LICENSE-DECISION.md) | [Leggi](LICENSE-DECISION.it.md) |
| Avviso | [Read](NOTICE) | [Leggi](NOTICE.it.md) |

## Sviluppo

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser
Invoke-Pester ./tests
```

```bash
bash -n install.sh src/the-switcher.sh tests/test-unix.sh
python3 -m py_compile src/the_switcher_unix.py
bash tests/test-unix.sh
```

La CI controlla PowerShell su Windows e il comportamento Unix su Ubuntu e macOS.

## Licenza

MIT. Il testo inglese invariato in [LICENSE](LICENSE) è canonico;
[la nota italiana](LICENSE.it.md) è soltanto informativa. Vedi la
[decisione sulla licenza](LICENSE-DECISION.it.md) e [NOTICE.it.md](NOTICE.it.md).

Topic GitHub: `codex-cli`, `openai`, `powershell`, `windows`, `linux`, `macos`,
`developer-tools`, `api-key-management`, `devex`, `cost-governance`, `ccusage`.
