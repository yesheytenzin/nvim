#!/usr/bin/env bash
# Prefetch everything this config needs at runtime so normal boots never
# download: Treesitter parsers + Mason LSP servers/tools + zls check.
# Idempotent: skips anything already installed.
# Usage: ~/.config/nvim/scripts/bootstrap.sh
set -euo pipefail
cd "$(dirname "$0")/.."

nvim --headless -c "luafile scripts/bootstrap.lua" 2>&1 | grep -v '^vim\.pack'
exit "${PIPESTATUS[0]}"
