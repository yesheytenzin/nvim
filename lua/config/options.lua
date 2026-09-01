-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Deferred to VeryLazy: saves /proc reads + OSC52 init at startup
vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", once = true, callback = function() require("config.remote_clipboard").setup() end })
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.scrolloff = 8 -- keep 8 lines visible above/below cursor (ThePrimagen tip)
vim.opt.sidescrolloff = 8 -- same for horizontal scrolling
vim.g.autoformat = false
vim.opt.timeoutlen = 100 -- faster leader recog (was 200) — 100ms = instant, 50ms if you type fast
vim.opt.ttimeoutlen = 10 -- key code fast
vim.opt.updatetime = 50 -- Primeagen 50ms (was 150) — faster CursorHold/diagnostics/which-key
vim.opt.guicursor = "" -- Primeagen: no blinking cursor
vim.opt.hlsearch = false
vim.opt.incsearch = true
-- vim.opt.colorcolumn = "80" -- Primeagen 80-char guide (Rails/C++ line length)
vim.opt.isfname:append("@-@")
vim.opt.mouse = ""
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.ttyfast = true
vim.opt.redrawtime = 1500
vim.opt.clipboard = "unnamedplus"
vim.o.winborder = "none" -- all floats borderless except blink (single)

-- Silence optional provider warnings (not needed for Rails API + C++ ide)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

vim.opt.synmaxcol = 300 -- don't highlight super long lines (C++ minified/generated)
vim.opt.maxmempattern = 20000

-- netrw: default neovim UI (vanilla) - no overrides, banner + thin list
-- (removed custom tree/banner settings to use stock defaults)

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 40 })
  end,
})

-- Fully disable mouse: no click, no scroll, no drag
vim.opt.mousescroll = "ver:0,hor:0"
vim.api.nvim_create_autocmd({ "OptionSet" }, {
  pattern = "mouse",
  callback = function()
    if vim.o.mouse ~= "" then
      vim.opt.mouse = ""
    end
  end,
})
