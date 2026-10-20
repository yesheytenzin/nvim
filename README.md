# nvim

Personal Neovim configuration, built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
Plugins are managed by Neovim's built-in **`vim.pack`** (no third-party plugin
manager). `lua/custom/pack.lua` adds trigger-driven lazy loading
(keys / cmd / ft / event) on top of `:packadd`; `nvim-pack-lock.json` pins
revisions.

Clone this repo (or symlink its checkout) at `~/.config/nvim`, then:

```bash
~/.config/nvim/scripts/bootstrap.sh   # prefetch parsers + Mason servers/tools
~/.config/nvim/scripts/verify.sh      # prove the install
```

If you are switching from the old `~/.config/nvim`, back it up first and keep
its git worktree intact; this repo reuses the same plugin store in
`~/.local/share/nvim/site/pack/core/opt`.

Requires `nvim >=0.12`, `git`, `make`, `rg`, `fd`, `fzf`, `clangd`,
`mise` (for the Ruby LSP), and `zls` (manual or `mise use -g zls`).

## Layout

| Path | Purpose |
|---|---|
| `init.lua` | startup order only: options → keymaps → plugins → behavior |
| `lua/custom/options.lua` | Primeagen editing defaults, UI, performance |
| `lua/custom/keymaps.lua` | global keymaps (movement, clipboard, windows, project) |
| `lua/custom/autocmds.lua` | project-root `lcd`, Ruby/YAML indents, big-file guard, trim-on-save |
| `lua/custom/pack.lua` | `vim.pack` + lazy triggers and per-plugin `config()` |
| `lua/custom/plugins/*.lua` | plugin specs, aggregated by `plugins/init.lua` |
| `lua/custom/terminal.lua` | reusable in-buffer terminal (<leader>ft / <leader>ot / <C-/>) |
| `lua/custom/remote_clipboard.lua` | OSC 52 + `wl-copy` for tmux/SSH |
| `lua/custom/omarchy_theme.lua` | Omarchy theme bridge + hot reload; rose-pine fallback |
| `lua/custom/lsp_manifest.lua` | servers, tools, gems (pinned versions) |
| `lua/custom/parser_manifest.lua` | Treesitter parsers wanted |
| `lua/custom/toolchain.lua` | `:Toolchain` status + save-to-install watcher |
| `scripts/` | headless bootstrap, verification, theme preinstall |

## Features

- **Search:** fzf-lua pickers (`<leader>ff/fg/fb/fr/fd`, `<leader>sg/sw/sW/ss/sS`, `<leader>sh`)
- **Navigation:** Harpoon 2 (`<leader>h`, `<leader>H`, `<leader>1-9`), aerial outline (`<leader>co`), persistence sessions (`<leader>qs/qS/ql/qd`)
- **Git:** fugitive (`<leader>gs/gp/gP/gt`), mergeui 3-pane merge (`<leader>gm`), gitsigns hunks (`<leader>gh*`)
- **Editor:** trouble (`<leader>xx/xX/cs/cS/xL/xQ`), undotree (`<leader>ut`), cloak for `.env*`, zen mode (`<leader>zz/zZ`), inc-rename (`<leader>cr`), Treesitter textobjects (`af/if`), mini.ai/surround
- **Rails:** vim-rails navigation (`<leader>ra/rA/rm/rc/rM/rv`) and ruby_lsp under the project's mise Ruby
- **LSP:** `lua_ls`, `clangd`, `ruby_lsp`, `rust_analyzer`, `pyright`, `bashls`, `zls`; diagnostics virtual text off by default (`<leader>ud` toggles)
- **Formatting:** conform with rubocop, yamlfmt, jq, clang-format, stylua, shfmt; manual `<leader>cf`
- **Completion:** blink.cmp (`enter` preset, buffer + path + snippets), friendly-snippets via native `vim.snippet`
- **Theme:** Omarchy-managed colorscheme with live reload; rose-pine-moon fallback

## Commands

- `:lua vim.pack.update()` — update plugins (vim.pack is Lua-only)
- `scripts/bootstrap.sh` — idempotent prefetch of parsers, Mason servers/tools, Ruby gems, zls check
- `scripts/verify.sh` — startup time, lazy-trigger checks, parser/LSP/tool pins, lockfile revisions
- `scripts/preinstall-omarchy-theme-plugins.sh` — prefetch every Omarchy theme colorscheme (optional; switches work without it)
- `:Toolchain` (`<leader>ci`) — wanted vs installed parsers/servers/tools, drift report
- `:lua R("custom.keymaps")` — hot-reload one module during development

Do not copy `~/.local/share/nvim/mason` between machines (its wrappers hardcode
`$HOME` paths). Copy this repo, then run `scripts/bootstrap.sh`.

## License

Two licenses live here, because this repo carries two lineages:

- `LICENSE` — Apache 2.0, the license this config was written under.
- `LICENSE-MIT.md` — MIT, the license of the kickstart.nvim base it was built on.
