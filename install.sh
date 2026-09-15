#!/usr/bin/env bash
set -eu

usage() {
    printf '%s\n' 'Usage: ./install.sh [--force] [--uninstall] [--profile PATH]'
}

force=0
uninstall=0
profile=''
while [ "$#" -gt 0 ]; do
    case "$1" in
        --force) force=1 ;;
        --uninstall) uninstall=1 ;;
        --profile) shift; [ "$#" -gt 0 ] || { usage >&2; exit 2; }; profile=$1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

command -v python3 >/dev/null 2>&1 || { printf '%s\n' 'python3 is required.' >&2; exit 1; }
python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 9))' || {
    printf '%s\n' 'Python 3.9 or newer is required.' >&2
    exit 1
}
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
install_dir="${SWITCHER_INSTALL_DIR:-$HOME/.the-switcher}"
installed_script="$install_dir/the-switcher.sh"
installed_helper="$install_dir/the_switcher_unix.py"

if [ -z "$profile" ]; then
    case "${SHELL:-}" in */zsh) profile="$HOME/.zshrc" ;; *) profile="$HOME/.bashrc" ;; esac
fi

if [ "$uninstall" -eq 1 ]; then
    python3 "$script_dir/src/the_switcher_unix.py" edit-profile \
        --profile "$profile" --script "$installed_script" --helper "$installed_helper" --remove
    printf 'Removed The Switcher profile block from %s. Local configuration and credentials were preserved.\n' "$profile"
    exit 0
fi

mkdir -p "$install_dir"
chmod 700 "$install_dir" 2>/dev/null || true
cp "$script_dir/src/the-switcher.sh" "$installed_script"
cp "$script_dir/src/the_switcher_unix.py" "$installed_helper"
chmod 700 "$installed_helper"

if [ ! -f "$install_dir/projects.json" ] || [ "$force" -eq 1 ]; then
    cp "$script_dir/templates/projects.unix.json" "$install_dir/projects.json"
    chmod 600 "$install_dir/projects.json" 2>/dev/null || true
fi

python3 "$installed_helper" edit-profile \
    --profile "$profile" --script "$installed_script" --helper "$installed_helper"

printf 'The Switcher was installed. Edit %s, then reload %s.\n' "$install_dir/projects.json" "$profile"
