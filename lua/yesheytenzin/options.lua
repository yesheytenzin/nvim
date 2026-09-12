-- Personal options layered under the Primeagen defaults in yesheytenzin/set.lua.
vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", once = true, callback = function() require("yesheytenzin.remote_clipboard").setup() end })
vim.opt.scrolloff = 8 -- keep 8 lines visible above/below cursor (ThePrimagen tip)
vim.opt.sidescrolloff = 8 -- same for horizontal scrolling
vim.g.autoformat = false
vim.opt.timeout = true
vim.opt.timeoutlen = 500 -- forgiving window for 3-key <leader> chords (space+p+f/s) incl. SSH/tmux jitter; 1000=nvim default, 300=too tight, misses when typed slow
vim.opt.ttimeoutlen = 50 -- key-code wait: 10ms drops <M-1> etc over SSH/tmux jitter; 50 stays snappy
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

-- Stock Neovim UI: no rounding, no smoothscroll, default PUM height
vim.opt.laststatus = 1 -- single statusline per window (stock default)
vim.opt.splitbelow = true -- predictable splits, no viewport jumps
vim.opt.splitright = true
vim.opt.shortmess:append("c") -- no "match X of Y" spam during completion

-- Enable mouse for scrolling/resizing (stock behavior)
vim.opt.mouse = "a"

-- Stock signcolumn: auto (will appear when needed)
vim.opt.signcolumn = "auto"

-- No bounded completion menu - use default
vim.opt.pumheight = 0