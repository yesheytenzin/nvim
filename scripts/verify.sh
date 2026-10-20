#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/check-behavior.sh

opt="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/core/opt"
printf 'installed plugins: %s\n' "$(find "$opt" -mindepth 1 -maxdepth 1 -type d | wc -l)"
printf 'lockfile entries:  %s\n' "$(python3 -c 'import json; print(len(json.load(open("nvim-pack-lock.json"))["plugins"]))')"

log="$(mktemp)"
trap 'rm -f "$log"' EXIT
nvim --headless --startuptime "$log" "+q" >/dev/null 2>&1
printf 'startup: %s\n' "$(grep 'NVIM STARTED' "$log" | awk '{print $1 " ms"}')"

set +e
nvim --headless -c "luafile scripts/verify.lua" 2>&1 | grep -v '^vim\.pack'
status="${PIPESTATUS[0]}"
set -e
exit "$status"
