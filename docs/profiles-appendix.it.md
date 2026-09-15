# Appendice — l'alternativa `--profile`

Più leggera dello standard `CODEX_HOME`: non crea cartelle separate e non usa
un wrapper. In cambio **non** isola credenziali e log, quindi non aiuta ad
attribuire i costi. È adatta se alterni due progetti e vuoi cambiare manualmente
modello o provider.

## Come funziona

Codex legge i profili come file dedicati accanto alla configurazione utente.
Ogni profilo punta a un `model_provider` personalizzato; ciascun provider
dichiara la variabile d'ambiente che contiene la chiave (`env_key`). Cambiare
profilo cambia chiave.

> Dalla versione 0.134.0, le sezioni `[profiles.<name>]` in `config.toml` sono
> deprecate: ogni profilo usa il proprio file `<name>.config.toml`.

## Passaggi

**1. Provider — `%USERPROFILE%\.codex\config.toml`**
Unisci queste sezioni alla configurazione esistente; vedi
`templates/user-config.toml.template`.

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

**2. Un file per profilo — `%USERPROFILE%\.codex\proj-1.config.toml`**
Modello: `templates/profile.config.toml.template`.

```toml
model_provider = "proj-1"
```

**3. Chiavi come variabili d'ambiente Windows dell'utente**
Esegui una sola volta e riavvia il terminale:

```powershell
setx OPENAI_API_KEY_PROJ_1 "sk-..."
setx OPENAI_API_KEY_PROJ_2 "sk-..."
```

`setx` salva la chiave nel registro utente **in chiaro**, leggibile da ogni
processo eseguito come te. È il compromesso di questo approccio. Se è un
problema, usa invece `CODEX_HOME` con keyring.

**4. Uso**

```powershell
codex --profile proj-1
codex exec --profile proj-1 "correggi i test non riusciti"
```

Puoi aggiungere scorciatoie al profilo PowerShell:

```powershell
function codex-proj-1 { codex --profile proj-1 @args }
function codex-proj-2 { codex --profile proj-2 @args }
```

## Limiti noti

- Un `.codex/config.toml` **a livello di progetto** non può impostare
  `profile`, `model_provider`, `openai_base_url` o credenziali. La scelta deve
  arrivare dalla riga di comando o da un wrapper; i soli profili non possono
  dunque passare automaticamente in base alla directory.
- Cronologia e log restano tutti in `~/.codex`: `ccusage` non può sapere quale
  chiave ha speso i token.
- La variabile `CODEX_PROFILE` compare in alcune build recenti, ma non è
  documentata come stabile: non basare il processo del team su di essa.

## Si possono combinare?

Sì. `CODEX_HOME` isola le credenziali; `--profile` cambia il modello *dentro*
un progetto, per esempio tra un profilo di revisione e uno economico. I file
dei profili vanno quindi nel `CODEX_HOME` del progetto e non in `~/.codex`.
