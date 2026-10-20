#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

nvim --headless -c "luafile scripts/bootstrap.lua" 2>&1 | grep -v '^vim\.pack'
exit "${PIPESTATUS[0]}"
