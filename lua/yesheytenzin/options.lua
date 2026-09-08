-- Personal options layered under the Primeagen defaults in yesheytenzin/set.lua.
vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", once = true, callback = function() require("yesheytenzin.remote_clipboard").setup() end })
vim.opt.scrolloff = 8 -- keep 8 lines visible above/below cursor (ThePrimagen tip)
vim.opt.sidescrolloff = 8 -- same for horizontal scrolling
vim.g.autoformat = false
vim.opt.timeoutlen = 300 -- reliable leader combos (was 100 too fast for <leader>ff) — 300=default, 200=fast, 100=misses if you type slow
vim.opt.ttimeoutlen = 10 -- key code fast
vim.opt.mouse = ""
vim.opt.undofile = true
vim.opt.undolevels = 10000
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undodir
vim.fn.mkdir(undodir, "p")
vim.opt.ttyfast = true
vim.opt.redrawtime = 1500
vim.opt.clipboard = "unnamedplus"
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
