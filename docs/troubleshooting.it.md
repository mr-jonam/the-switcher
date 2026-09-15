# Risoluzione dei problemi

[English](troubleshooting.md) | Italiano

| Sintomo | Causa / soluzione |
|---|---|
| `cannot be loaded because running scripts is disabled` | Esegui `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, oppure avvia con `-ExecutionPolicy Bypass`. |
| `codex` parte ma non mostra il banner `[codex] ...` | Il profilo non è stato ricaricato: apri un nuovo terminale oppure esegui `. $PROFILE`. |
| `Executable 'codex' not found on PATH` | Installa Codex CLI o imposta `$env:SWITCHER_CODEX_EXE`. |
| `Project map not found` | Manca `projects.json` oppure `SWITCHER_CONFIG` punta altrove. |
| Login rifiutato con `--with-api-key` | La build di Codex CLI è datata: esegui `Use-CodexProject <nome>`, quindi `codex login` interattivo. |
| L'estensione VS Code usa la chiave sbagliata | CLI ed estensione IDE condividono lo stato di login: avvia l'IDE da un terminale nel quale il progetto è già risolto. |
| In un repo viene scelto il progetto errato | Controlla `ResolvedBy` in `Get-CodexProject`; il marker `.codexproject` prevale sulla mappa `paths`. |
| `python3 is required` su Linux/macOS | Installa Python 3 oppure imposta `SWITCHER_PYTHON` dopo l’installazione se usa un nome non standard. |
| `switcher_connect: read: -s` fallisce | Carica l’integrazione in Bash o Zsh; le altre shell POSIX non sono supportate. |
| Il login non accede al keyring su Linux | Avvia un keyring Secret Service sbloccato; le sessioni headless potrebbero non fornirlo. |
| I comandi mancano dopo `install.sh` | Ricarica `~/.bashrc` o `~/.zshrc`, oppure esegui `exec "$SHELL" -l`. |
| `Access is denied` leggendo file del repo, anche elevato | Di solito non è un ACL: controlla Defender Controlled Folder Access, file OneDrive solo cloud (attributo `O`) o Mark-of-the-Web da ZIP (`Get-ChildItem -Recurse \| Unblock-File`). Spostare il repo in `C:\dev\...` evita tutti e tre i casi. |

## I file sono sbloccati ma lo strumento non legge ancora

Esegui nella root del repository e confronta ciò che puoi fare tu con il
processo che esegue lo strumento:

```powershell
whoami
Get-Acl .\README.md | Format-List Owner, AccessToString
Get-Item .\README.md -Force | Select-Object Name, Attributes
Get-Item .\README.md -Stream * -EA SilentlyContinue | Select-Object Stream
Get-MpPreference | Select-Object EnableControlledFolderAccess
Get-Content .\README.md -TotalCount 1
```

Se l'ultima riga funziona per te ma non per lo strumento, il file è integro:
il blocco è circoscritto a quel processo (Controlled Folder Access, EDR o
sandbox dell'agente), non al filesystem.
