# nvim

Personal Neovim config.

```bash
git clone https://github.com/yesheytenzin/nvim.git ~/.config/nvim && nvim
```

Plugins are managed by Neovim's built-in **`vim.pack`** (no third-party plugin
manager). `lua/pack.lua` adds trigger-driven lazy loading (keys / cmd / ft /
event / colorscheme) on top of `:packadd`; `nvim-pack-lock.json` pins revisions.

Requires `nvim >=0.12`, `git`, `make`, `rg`, `fd`, `clangd`.

- `:lua vim.pack.update()` — update plugins (no `:Pack`/`:Lazy` command; vim.pack is Lua-only)
- The lockfile is `nvim-pack-lock.json`
- `scripts/bootstrap.sh` — prefetch Treesitter parsers + Mason LSP/tools once
  per machine so later boots never download (idempotent; `scripts/verify.sh`
  proves the cache is complete)
- Manifests: `lua/parser_manifest.lua` + `lua/lsp_manifest.lua` declare every
  wanted parser/server/tool (versions pinned) — saving either file installs
  what was added, and `:Toolchain` (`<leader>ci`) shows wanted vs installed
- Moving machines: copy the repo, then run `scripts/bootstrap.sh` — do NOT
  copy `~/.local/share/nvim/mason` (its wrappers hardcode `$HOME` paths).
  Fresh installs resolve exact pinned versions, no surprises.
