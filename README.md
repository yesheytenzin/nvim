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
| `init.lua` | startup order: options, keymaps, behavior hooks, plugin loader, theme |
| `lua/custom/options.lua` | Primeagen editing defaults, UI, performance |
| `lua/custom/keymaps.lua` | global keymaps (movement, clipboard, windows, project) |
| `lua/custom/autocmds.lua` | project-root `lcd`, Ruby/YAML indents, big-file guard, trim-on-save |
| `lua/custom/pack.lua` | `vim.pack` + lazy triggers and per-plugin `config()` |
| `lua/custom/plugins/*.lua` | plugin specs, aggregated by `plugins/init.lua` |
| `lua/custom/lsp/*.lua` | LSP attach maps, server policy, and Ruby index refresh |
| `lua/custom/terminal.lua` | reusable in-buffer terminal (<C-/>) |
| `lua/custom/remote_clipboard.lua` | OSC 52 + `wl-copy` for tmux/SSH |
| `lua/custom/omarchy_theme.lua` | Omarchy theme bridge + hot reload; rose-pine fallback |
| `lua/custom/lsp_manifest.lua` | servers, tools, gems (pinned versions) |
| `lua/custom/parser_manifest.lua` | Treesitter parsers wanted |
| `lua/custom/toolchain.lua` | `:Toolchain` status + save-to-install watcher |
| `lua/custom/health.lua` | `:checkhealth custom` — version and external tools |
| `lua/examples/*.lua` | optional kickstart setups; not loaded, copy from them |
| `scripts/` | headless bootstrap, verification, theme preinstall |

## Features

- **Search:** fzf-lua pickers (`<leader>ff/fg/fb/fr/fd`, `<leader>sg/sw/sW/ss/sS`, `<leader>sh`)
- **Navigation:** Harpoon 2 (`<leader>ha` add, `<leader>hm` menu, `<leader>1-9` jump), aerial outline (`<leader>co`), persistence sessions (`<leader>qs/qS/ql/qd`)
- **Git:** fugitive (`<leader>gs/gp/gP/gu`), mergeui 3-pane merge (`<leader>gm`, take left/right with `gh`/`gl`), gitsigns hunks (`]h`/`[h`, `<leader>gh*`)
- **Editor:** trouble (`<leader>xx/xb/xl/xq/cl`), undotree (`<leader>ut`), cloak for `.env*`, zen mode (`<leader>zz/zZ`), inc-rename (`<leader>cr`), Treesitter textobjects (`af/if`), mini.ai/surround
- **Rails:** vim-rails navigation (`<leader>ra/rr/rm/rc/rv/rd`) and ruby_lsp under the project's mise Ruby
- **LSP:** `lua_ls`, `clangd`, `ruby_lsp`, `rust_analyzer`, `pyright`, `bashls`, `zls`; diagnostics virtual text off by default (`<leader>ud` toggles)
- **Formatting:** conform with rubocop, yamlfmt, jq, clang-format, stylua, shfmt; manual `<leader>cf`
- **Completion:** blink.cmp (`Tab` accepts the top item, `<C-n>`/`<C-p>` pick one and `Enter` accepts it, otherwise `Enter` is a plain new line), LSP preferred over path, snippets + buffer fallbacks, friendly-snippets via native `vim.snippet`; methods defined in the current Ruby file complete instantly
- **Run & test:** `<leader>tr` runs the current file (ruby/python/lua/sh/node) and `<leader>tt` runs its `_test.rb`/`_spec.rb` (minitest, rspec, or `bin/rails test`) in the `<C-/>` terminal; `<leader>tl` reruns the last one
- **Debugger:** nvim-dap + dap-ui + rdbg for Ruby — `F9`/`Shift-F9` breakpoint/conditional, `F5` start/continue, `F10`/`F11`/`F12` over/into/out, `Shift-F5` stop
- **Reading code:** Treesitter folding (`za`, everything starts open), sticky `class`/`def` header (`<leader>uc`), indent guide with `[i`/`]i` jumps, highlight of the word under the cursor, inlay hints (`<leader>uh`)
- **Project replace:** grug-far (`<leader>sR`, prefilled with the word under the cursor)
- **Windows, buffers, tabs:** `<C-h/j/k/l>` move between splits, `<leader>ws`/`wv` split below/right, `<leader>wd` close, `<leader>wo` close others; `Shift-l`/`Shift-h` next/previous buffer in the tab bar, `Q` close buffer (layout kept), `<leader>bo` close other buffers; a tab bar at the top lists open buffers (tab pages numbered on the right); `<leader><tab><tab>` open buffer in a new tab, `<leader><tab>n` new empty tab, `]t`/`[t` next/previous tab, `<leader><tab>d` close tab, `<leader><tab>o` close other tabs
- **Auto-close:** nvim-autopairs closes brackets/quotes and adds `end` after `def`/`class`/`module`/`do`/`if`/`case`/… (Ruby) and `function`/`then`/`do` (Lua), skipping blocks that are already closed; nvim-ts-autotag closes and renames HTML/ERB tags; yanked text flashes briefly
- **Theme:** Omarchy-managed colorscheme with live reload; rose-pine-moon fallback

## Commands

- `:lua vim.pack.update()` — update plugins (vim.pack is Lua-only)
- `scripts/bootstrap.sh` — idempotent prefetch of parsers, Mason servers/tools, Ruby gems, zls check
- `scripts/check-behavior.sh` — isolated loader, manifest, completion, and terminal behavior checks
- `scripts/verify.sh` — focused tests, startup, lazy triggers, parser/LSP/tool pins, and lockfile revisions
- `scripts/preinstall-omarchy-theme-plugins.sh` — prefetch every Omarchy theme colorscheme (optional; switches work without it)
- `:Toolchain` (`<leader>ci`) — wanted vs installed parsers/servers/tools, drift report
- `:ConfigReload custom.keymaps` — hot-reload one module during development
- `:checkhealth custom` — Neovim version and the external tools this config needs

The Omarchy theme bridge executes the machine-managed
`~/.local/state/omarchy/current/theme/neovim.lua` file. Treat that file as
trusted configuration. Theme load and setup failures appear as Neovim errors.

Do not copy `~/.local/share/nvim/mason` between machines (its wrappers hardcode
`$HOME` paths). Copy this repo, then run `scripts/bootstrap.sh`.

## License

Two licenses live here, because this repo carries two lineages:

- `LICENSE` — Apache 2.0, the license this config was written under.
- `LICENSE-MIT.md` — MIT, the license of the kickstart.nvim base it was built on.
