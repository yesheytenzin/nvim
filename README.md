# nvim

Personal Neovim config — Rails API + C++ focused, pure `lazy.nvim` (no LazyVim distro), Omarchy-aware.

Forked from [LazyVim starter](https://github.com/LazyVim/LazyVim) and heavily customized.

## Highlights
- **Primeagen-inspired** remaps: `J` keep cursor, `v J/K` move lines, `<leader>p` paste without yank, `<leader>y/Y/d` clipboard/blackhole, `C-d/u` + `n/N` centered `zz`, `C-k/j` quickfix, `<leader>s` substitute word, `<leader>x` chmod +x, `hlsearch=false` / `updatetime=50` / `colorcolumn=80`
- **LSP**: `ruby-lsp` + `clangd` (`--background-index --clang-tidy`), `fidget.nvim` progress, `LspAttach` maps `gd`, `K`, `<leader>v*`, `[d`/`]d`
- **Git**: `tpope/vim-fugitive` (`<leader>gs/p/P/t`, `gu/gh`) + `mergeui.nvim` 3-pane merge (`<leader>gm`)
- **Search**: `telescope.nvim` + `fzf-native` (`<leader>ff/fg/fb/fh/fo/fs`, `<leader>pws/pWs/ps` word grep), `inc-rename.nvim`
- **Navigation**: `ThePrimeagen/harpoon2` (`<leader>ha/hm/h1-4`), `other.nvim` Rails alternates (`<leader>ro`), `vim-rails`, `aerial`
- **Editing**: `conform.nvim` (`rubocop`, `clang_format`, `yamlfmt`, `jq`), `blink.cmp`, `treesitter` + `textobjects` (`af/if`), `nvim-treesitter` auto-start
- **UI**: `aether` (Omarchy `v3`) with `omarchy-theme-hotreload` (hot-reloads on `omarchy theme` change), `which-key` 80ms, `neoscroll` smooth centered, `trouble` (`<leader>tt`), `zen-mode` (`<leader>zz/zZ`), `undotree` (`<leader>u`), `cloak.nvim` for `.env*`
- **Workspace**: `persistence.nvim` sessions, `remote_clipboard` OSC52 + Wayland, Omarchy clipboard bridge

## Structure
```
init.lua                 # bootstrap lazy.nvim
lua/config/
  lazy.lua               # lazy.nvim setup
  options.lua            # Primeagen set.lua + Omarchy opts
  keymaps.lua            # Primeagen remap.lua + Rails/C++
  autocmds.lua           # yank hl, trim whitespace, LspAttach
  remote_clipboard.lua
  theme.lua              # Omarchy theme bridge
lua/plugins/
  theme.lua              # ← aether (committed as file, Omarchy restores symlink)
  primeagen.lua          # undotree, trouble, fidget, cloak, zen, textobjects
  fugitive.lua
  harpoon.lua
  navigation.lua         # telescope + inc-rename
  coding.lua             # conform + mason
  ...
```

## Install
```bash
git clone https://github.com/yesheytenzin/nvim.git ~/.config/nvim
nvim  # lazy.nvim bootstraps on first run
:checkhealth
```

Omarchy users: theme is auto-linked via `omarchy-theme-hotreload`. Non-Omachy: `:colorscheme aether` or `tokyonight`/`kanagawa`.

## Keymaps (Primeagen + custom)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>pv` | n | Netrw `Ex` |
| `<leader>u` | n | Undotree |
| `<leader>gs` | n | Fugitive `:Git` |
| `<leader>p/P/t` | n | Fugitive push/pull/push -u (in fugitive buffer) |
| `gu/gh` | n | diffget //2 //3 |
| `<leader>ha/hm/h1-4/hc` | n | Harpoon |
| `<leader>pws/pWs/ps` | n | Grep cword/CWORD/prompt |
| `<leader>s` | n | Substitute word |
| `<leader>tt` | n | Trouble |
| `<leader>zz/zZ` | n | Zen |

See `lua/config/keymaps.lua` and `lua/plugins/primeagen.lua` for full list.

## Requirements
- Neovim >= 0.10
- `git`, `make`, `ripgrep`, `fd`, `clangd`, `rubocop`, `wl-clipboard` (Wayland)
