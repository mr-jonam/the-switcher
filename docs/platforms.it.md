# Piattaforme e installazione

[English](platforms.md) | Italiano

## Windows

Usa Windows 10/11 con Windows PowerShell 5.1 o PowerShell 7+. Esegui
`powershell -ExecutionPolicy Bypass -File .\install.ps1`, apri un nuovo
terminale, modifica `%USERPROFILE%\.the-switcher\projects.json`, quindi esegui
`Connect-CodexProject proj-1`.

Eseguire di nuovo l’installer aggiorna il modulo senza duplicare il blocco nel
profilo. `-Force` sostituisce la mappa fittizia locale; `-Uninstall` rimuove
soltanto l’integrazione gestita.

## Linux

Installa Python 3.9+ e usa Bash o Zsh. Deve essere disponibile un keyring grafico
compatibile con Secret Service quando Codex salva le credenziali in modalità `keyring`.

```bash
bash ./install.sh
exec "$SHELL" -l
${EDITOR:-vi} "$HOME/.the-switcher/projects.json"
switcher_connect proj-1
```

I sistemi headless potrebbero non esporre un keyring desktop sbloccato. Verifica
l’autenticazione Codex prima di affidarti all’ambiente; non usare credenziali in
chiaro su un host condiviso.

## macOS

Servono Python 3.9+ e Zsh o Bash. Zsh viene rilevata da `$SHELL`, quindi il profilo
predefinito è `~/.zshrc`. La modalità `keyring` di Codex usa il Portachiavi di sistema.

```bash
bash ./install.sh
exec "$SHELL" -l
switcher_connect proj-1
```

## Opzioni dell’installer

```text
./install.sh --force              sostituisce il projects.json fittizio
./install.sh --profile PERCORSO   gestisce un profilo Bash/Zsh specifico
./install.sh --uninstall          rimuove il blocco gestito dal profilo
```

La disinstallazione conserva `~/.the-switcher`, le directory `CODEX_HOME` e le
voci nel credential store. Rimuovile separatamente solo dopo aver verificato i percorsi.

## Ciclo di vita della shell

L’integrazione Unix viene caricata nel profilo: ricaricalo dopo l’installazione.
`switcher_use proj-1` agisce soltanto sulla shell corrente e sui processi figli.

```bash
unset SWITCHER_PROJECT  # torna alla risoluzione dalla directory
switcher_project
```

Usa `SWITCHER_CONFIG`, `SWITCHER_CODEX_EXE`, `SWITCHER_PYTHON` o
`SWITCHER_HELPER` soltanto quando i valori predefiniti non sono adatti.
