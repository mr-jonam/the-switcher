#!/usr/bin/env bash
set -eu

repo_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/dev/proj-1/sub" "$test_root/dev/proj-10" "$test_root/marked/child" "$test_root/other"

cat > "$test_root/projects.json" <<EOF
{
  "default": "proj-default",
  "projects": {
    "proj-default": {"codexHome": "$test_root/homes/default", "paths": []},
    "proj-1": {"apiKeyName": "KEY_PROJ_1", "codexHome": "$test_root/homes/proj-1", "paths": ["$test_root/dev/proj-1"]},
    "proj-2": {"apiKeyName": "KEY_PROJ_2", "codexHome": "$test_root/homes/proj-2", "paths": []}
  }
}
EOF
printf '%s\n' '# project marker' 'proj-2' > "$test_root/marked/.codexproject"
export SWITCHER_CONFIG="$test_root/projects.json"
helper="$repo_dir/src/the_switcher_unix.py"

assert_name() {
    expected=$1
    shift
    actual=$(python3 "$helper" resolve "$@")
    actual=${actual%%|*}
    [ "$actual" = "$expected" ] || { printf 'Expected %s, got %s\n' "$expected" "$actual" >&2; exit 1; }
}

assert_name proj-1 --path "$test_root/dev/proj-1/sub"
assert_name proj-default --path "$test_root/dev/proj-10"
assert_name proj-2 --path "$test_root/marked/child"
assert_name proj-default --path "$test_root/other"
assert_name proj-1 --name proj-1 --path "$test_root/marked/child"

profile="$test_root/profile"
python3 "$helper" edit-profile --profile "$profile" --script "$repo_dir/src/the-switcher.sh" --helper "$helper"
python3 "$helper" edit-profile --profile "$profile" --script "$repo_dir/src/the-switcher.sh" --helper "$helper"
[ "$(grep -c '^# >>> the-switcher >>>$' "$profile")" -eq 1 ]
python3 "$helper" edit-profile --profile "$profile" --script "$repo_dir/src/the-switcher.sh" --helper "$helper" --remove
if grep -q 'the-switcher' "$profile"; then
    printf '%s\n' 'Managed profile block was not removed.' >&2
    exit 1
fi

incomplete_profile="$test_root/incomplete-profile"
printf '%s\n' 'keep-this-line' '# >>> the-switcher >>>' 'incomplete-block' > "$incomplete_profile"
python3 "$helper" edit-profile --profile "$incomplete_profile" --script "$repo_dir/src/the-switcher.sh" --helper "$helper" --remove
grep -q '^incomplete-block$' "$incomplete_profile"

export SWITCHER_HELPER="$helper"
export SWITCHER_PYTHON=python3
# shellcheck source=src/the-switcher.sh
. "$repo_dir/src/the-switcher.sh"
switcher_use proj-1 >/dev/null
[ "$SWITCHER_PROJECT" = 'proj-1' ]

printf '%s\n' 'Unix tests passed.'
