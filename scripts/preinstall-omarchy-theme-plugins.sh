#!/bin/bash

set -euo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/pack/core/opt"
mkdir -p "$DATA"

declare -A PLUGINS=(
  ["catppuccin/nvim"]="catppuccin"
  ["neanias/everforest-nvim"]="everforest-nvim"
  ["ellisonleao/gruvbox.nvim"]="gruvbox.nvim"
  ["bjarneo/hackerman.nvim"]="hackerman.nvim"
  ["bjarneo/aether.nvim"]="aether"
  ["omacom-io/lumon.nvim"]="lumon.nvim"
  ["tahayvr/matteblack.nvim"]="matteblack.nvim"
  ["EdenEast/nightfox.nvim"]="nightfox.nvim"
  ["ribru17/bamboo.nvim"]="bamboo.nvim"
  ["OldJobobo/retro-82.nvim"]="retro-82.nvim"
  ["rose-pine/neovim"]="rose-pine"
  ["ficcdaf/ashen.nvim"]="ashen.nvim"
  ["folke/tokyonight.nvim"]="tokyonight.nvim"
  ["kepano/flexoki-neovim"]="flexoki-neovim"
  ["rebelot/kanagawa.nvim"]="kanagawa.nvim"
)

for repo in "${!PLUGINS[@]}"; do
  dir="$DATA/${PLUGINS[$repo]}"
  if [[ -d $dir/.git ]]; then
    echo "ok        ${PLUGINS[$repo]} (already installed)"
  else
    echo "cloning   ${PLUGINS[$repo]} ..."
    rm -rf "$dir"
    git clone --quiet --filter=blob:none --single-branch \
      "https://github.com/$repo.git" "$dir"
    echo "installed ${PLUGINS[$repo]}"
  fi
done

echo "Done. Future omarchy theme switches will not download nvim plugins."
