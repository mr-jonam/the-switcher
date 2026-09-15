# The Switcher

**La chiave giusta, scelta dalla cartella in cui sei.**

Switch automatico delle API key OpenAI per progetto su [Codex CLI](https://developers.openai.com/codex)
per Windows. Un `CODEX_HOME` per progetto, risolto dalla directory corrente:
niente più login manuali, credenziali isolate e attribuzione dei token per chiave
senza lavoro extra.

🇬🇧 [Read in English](README.md)

---

## Il problema

Codex CLI tiene **una sola identità attiva per volta**: le credenziali stanno in
`%USERPROFILE%\.codex` o nel Credential Manager. Chi lavora su più commesse con
chiavi diverse finisce per rifare `codex login` a ogni cambio di contesto, o per
usare la chiave sbagliata e imputare i token alla commessa sbagliata — con tutti
i log di sessione mescolati in un'unica cartella.

Il `.codex/config.toml` di progetto non risolve: per sicurezza non può
sovrascrivere credenziali, `model_provider`, `openai_base_url` né `profile`.

## Come funziona

`CODEX_HOME` sposta l'intero stato di Codex: `config.toml`, credenziali,
cronologia e **log di sessione**. The Switcher ne assegna uno per progetto, e un
wrapper PowerShell sceglie quello giusto prima di lanciare il vero `codex`.

Ordine di risoluzione:

1. nome esplicito (`Use-CodexProject proj-1`)
2. file **`.codexproject`** nella root del repo (risale l'albero delle cartelle)
3. mappa `paths` in `projects.json` (vince il prefisso più lungo)
4. progetto `default`

Il punto 2 è quello che conta in team: il file sta nel repo, quindi chi lo clona
usa la chiave corretta senza configurare nulla.

## Installazione

Requisiti: Windows 10/11, PowerShell 5.1 o 7.x, Codex CLI
(`npm i -g @openai/codex`), una API key per progetto.

```powershell
git clone https://github.com/mr-jonam/the-switcher.git
cd the-switcher
powershell -ExecutionPolicy Bypass -File .\install.ps1

# apri un NUOVO terminale, poi
notepad $HOME\.the-switcher\projects.json   # mappa i tuoi progetti
Connect-CodexProject proj-1                 # login una tantum per chiave
Get-CodexProject                            # verifica
```

L'installer è idempotente e si disinstalla con `.\install.ps1 -Uninstall`.

## Configurare i progetti

Dopo l'installazione apri `%USERPROFILE%\.the-switcher\projects.json`. Il file
contiene solo nomi fittizi (`proj-default`, `proj-1`, `proj-2`, `proj-3`):
sostituiscili, insieme ai percorsi, con gli identificativi e le cartelle che usi.

Per ogni progetto completa:

| Campo | Cosa inserire |
|---|---|
| nome progetto | identificativo breve e univoco, usato da `Use-CodexProject` e `.codexproject` |
| `description` | etichetta locale facoltativa |
| `apiKeyName` | etichetta per riconoscere la chiave; **non la chiave API** |
| `codexHome` | cartella distinta, normalmente `%USERPROFILE%\\.codex-homes\\<progetto>` |
| `paths` | percorsi assoluti le cui sottocartelle appartengono al progetto |

Per aggiungerne uno, duplica un blocco `proj-*` e modifica tutti i valori:

```json
"proj-3": {
  "description": "Example project 3; replace this text",
  "apiKeyName": "KEY_PROJ_3",
  "codexHome": "%USERPROFILE%\\.codex-homes\\proj-3",
  "paths": ["C:\\dev\\proj-3"]
}
```

Poi esegui `Connect-CodexProject proj-3`. Facoltativamente, metti `proj-3` in
un file `.codexproject` nella root del repository e committa solo quel marker:
ogni utente conserva la propria mappa locale e fa login separatamente.

## Comandi

| Comando | Cosa fa |
|---|---|
| `codex` | lancia Codex con il `CODEX_HOME` del progetto corrente |
| `Get-CodexProject` | progetto risolto, chiave attesa, da dove è stato dedotto, stato login |
| `Use-CodexProject <nome>` (alias `cxp`) | forza un progetto per la sessione |
| `Connect-CodexProject <nome>` | login con API key nel `CODEX_HOME` di quel progetto |
| `Get-CodexUsage -Period daily` | report token per progetto via `ccusage` |

Variabili d'ambiente: `SWITCHER_CONFIG`, `SWITCHER_CODEX_EXE`, `SWITCHER_QUIET=1`.

## Dove finisce ogni file

| File | Destinazione |
|---|---|
| `src/TheSwitcher.psm1` | `%USERPROFILE%\.the-switcher\TheSwitcher.psm1` |
| `templates/projects.json` | `%USERPROFILE%\.the-switcher\projects.json` |
| `templates/config.toml.template` | `%USERPROFILE%\.codex-homes\<progetto>\config.toml` |
| `templates/.codexproject` | **root del repository** (da committare) |
| blocco nel profilo | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |

## Sicurezza

- Nessuna API key nel repo, nei template o in `projects.json`.
- `Connect-CodexProject` legge la chiave in input mascherato e la passa a
  `codex login --with-api-key` via **stdin**: non finisce nella cronologia di
  PowerShell né nella riga di comando.
- `cli_auth_credentials_store = "keyring"`: credenziali nel Credential Manager,
  non in un `auth.json` in chiaro. La voce è derivata dal percorso del
  `CODEX_HOME`, quindi l'isolamento per progetto vale anche così.
- Non committare mai `auth.json` né il contenuto di `.codex-homes\` (già in
  `.gitignore`). L'unico file pensato per stare in un repo è `.codexproject`.

## Documentazione

- [Appendice profili](docs/profiles-appendix.md) | [Italiano](docs/profiles-appendix.it.md)
  — l'alternativa `--profile`.
- [Troubleshooting](docs/troubleshooting.md) | [Italiano](docs/troubleshooting.it.md)
  — execution policy, "Access is denied", estensione IDE.

## Licenza

MIT — vedi [LICENSE](LICENSE).
