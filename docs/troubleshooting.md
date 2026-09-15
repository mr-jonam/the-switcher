# Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `cannot be loaded because running scripts is disabled` | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`, or launch with `-ExecutionPolicy Bypass` |
| `codex` runs but prints no `[codex] ...` banner | the profile wasn't reloaded: open a new terminal, or `. $PROFILE` |
| `Executable 'codex' not found on PATH` | install Codex CLI, or set `$env:SWITCHER_CODEX_EXE` |
| `Project map not found` | `projects.json` is missing, or `SWITCHER_CONFIG` points elsewhere |
| Login rejected with `--with-api-key` | older Codex CLI build: run `Use-CodexProject <name>` then interactive `codex login` |
| The VS Code extension uses the wrong key | CLI and IDE extension share login state — the IDE has to see the same `CODEX_HOME`; launch it from a terminal where the project is already resolved |
| The wrong project is picked in a repo | check the `ResolvedBy` field of `Get-CodexProject`; the `.codexproject` marker beats the `paths` map |
| `Access is denied` reading repo files, even elevated | usually not an ACL. Check Defender **Controlled Folder Access** (it blocks unapproved apps under Desktop/Documents and ignores elevation), OneDrive cloud-only files (attribute `O`), or Mark-of-the-Web from an extracted ZIP (`Get-ChildItem -Recurse \| Unblock-File`). Moving the repo to `C:\dev\...` sidesteps all three. |

## Files were unblocked but a tool still can't read them

Run this in the repo and compare what *you* can do with what the tool can:

```powershell
whoami
Get-Acl .\README.md | Format-List Owner, AccessToString
Get-Item .\README.md -Force | Select-Object Name, Attributes
Get-Item .\README.md -Stream * -EA SilentlyContinue | Select-Object Stream
Get-MpPreference | Select-Object EnableControlledFolderAccess
Get-Content .\README.md -TotalCount 1
```

If the last line works for you but the tool still fails, the file is fine — what
is blocking is scoped to that process (Controlled Folder Access, EDR, or the
agent's own sandbox), not to the filesystem.
