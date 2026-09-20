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
