#!/usr/bin/env bash
# Source this file from Bash or Zsh. Do not execute it directly.

SWITCHER_HELPER="${SWITCHER_HELPER:-$HOME/.the-switcher/the_switcher_unix.py}"
SWITCHER_PYTHON="${SWITCHER_PYTHON:-python3}"

_switcher_resolve() {
    local result explicit_path
    explicit_path="${2:-$PWD}"
    if [ -n "${1:-}" ]; then
        result=$("$SWITCHER_PYTHON" "$SWITCHER_HELPER" resolve --name "$1" --path "$explicit_path") || return $?
    else
        result=$("$SWITCHER_PYTHON" "$SWITCHER_HELPER" resolve --path "$explicit_path") || return $?
    fi
    IFS='|' read -r SWITCHER_RESOLVED_NAME SWITCHER_RESOLVED_HOME SWITCHER_RESOLVED_KEY SWITCHER_RESOLVED_BY <<< "$result"
    [ -n "$SWITCHER_RESOLVED_NAME" ] && [ -n "$SWITCHER_RESOLVED_HOME" ]
}

_switcher_codex_executable() {
    if [ -n "${SWITCHER_CODEX_EXE:-}" ]; then
        printf '%s\n' "$SWITCHER_CODEX_EXE"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        whence -p codex
    else
        type -P codex
    fi
}

_switcher_prepare_home() {
    local home_path="$1"
    mkdir -p "$home_path" || return $?
    chmod 700 "$home_path" 2>/dev/null || true
    if [ ! -f "$home_path/config.toml" ]; then
        printf '%s\n' 'cli_auth_credentials_store = "keyring"' > "$home_path/config.toml" || return $?
        chmod 600 "$home_path/config.toml" 2>/dev/null || true
    fi
}

switcher_project() {
    _switcher_resolve "${SWITCHER_PROJECT:-}" "${1:-$PWD}" || return $?
    printf '%s\n' "Project:     $SWITCHER_RESOLVED_NAME"
    printf '%s\n' "Key label:   $SWITCHER_RESOLVED_KEY"
    printf '%s\n' "CODEX_HOME:  $SWITCHER_RESOLVED_HOME"
    printf '%s\n' "Resolved by: $SWITCHER_RESOLVED_BY"
}

switcher_use() {
    [ "$#" -eq 1 ] || { printf '%s\n' 'Usage: switcher_use <project>' >&2; return 2; }
    _switcher_resolve "$1" "$PWD" || return $?
    export SWITCHER_PROJECT="$SWITCHER_RESOLVED_NAME"
    switcher_project "$PWD"
}

switcher_connect() {
    local executable api_key status
    [ "$#" -eq 1 ] || { printf '%s\n' 'Usage: switcher_connect <project>' >&2; return 2; }
    _switcher_resolve "$1" "$PWD" || return $?
    executable=$(_switcher_codex_executable) || {
        printf '%s\n' "the-switcher: Codex executable not found; install it or set SWITCHER_CODEX_EXE" >&2
        return 127
    }
    _switcher_prepare_home "$SWITCHER_RESOLVED_HOME" || return $?
    printf 'API key for %s: ' "$SWITCHER_RESOLVED_NAME" >&2
    IFS= read -r -s api_key || { printf '\n' >&2; return 1; }
    printf '\n' >&2
    [ -n "$api_key" ] || { printf '%s\n' 'the-switcher: API key cannot be empty' >&2; return 2; }
    printf '%s' "$api_key" | CODEX_HOME="$SWITCHER_RESOLVED_HOME" "$executable" login --with-api-key
    status=$?
    unset api_key
    return "$status"
}

switcher_usage() {
    local period="${1:-daily}" project="${2:-}"
    case "$period" in daily|monthly|session) ;; *) printf '%s\n' 'Usage: switcher_usage [daily|monthly|session] [project]' >&2; return 2 ;; esac
    _switcher_resolve "$project" "$PWD" || return $?
    CODEX_HOME="$SWITCHER_RESOLVED_HOME" npx ccusage@latest codex "$period"
}

switcher_help() {
    printf '%s\n' \
        'codex [args]                         Run Codex for the resolved project' \
        'switcher_project [path]              Show the resolved project' \
        'switcher_use <project>               Pin a project in this shell' \
        'switcher_connect <project>           Store its API key through Codex login' \
        'switcher_usage [period] [project]    Report usage with ccusage' \
        'cxp <project>                        Alias for switcher_use'
}

codex() {
    local executable selected="${SWITCHER_PROJECT:-}"
    _switcher_resolve "$selected" "$PWD" || return $?
    executable=$(_switcher_codex_executable) || {
        printf '%s\n' "the-switcher: Codex executable not found; install it or set SWITCHER_CODEX_EXE" >&2
        return 127
    }
    _switcher_prepare_home "$SWITCHER_RESOLVED_HOME" || return $?
    if [ "${SWITCHER_QUIET:-0}" != "1" ]; then
        printf '[codex] %s | %s | %s\n' "$SWITCHER_RESOLVED_NAME" "$SWITCHER_RESOLVED_KEY" "$SWITCHER_RESOLVED_HOME" >&2
    fi
    CODEX_HOME="$SWITCHER_RESOLVED_HOME" "$executable" "$@"
}

cxp() {
    switcher_use "$@"
}
