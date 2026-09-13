-- Single source of truth for vim options: Primeagen's editing defaults plus
-- environment, UI, and performance tuning. Sectioned, not split: an earlier
-- set.lua/options.lua split shared one interface (global vim.opt) with no
-- seam between them, so they are merged here.
--
-- Portable editor behavior only. Machine-specific clipboard lives in
-- remote_clipboard; filetype indents live in autocmds.lua.

-- ── Editing (Primeagen base) ─────────────────────────────────────────────
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true -- wrap at word boundaries, not mid-word
vim.opt.breakindent = true -- wrapped lines keep the original line's indent
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 200 -- CursorHold cadence: 50 fires LSP/fidget handlers 20x/sec; 200 stays snappy

-- ── Cursor context ───────────────────────────────────────────────────────
vim.opt.scrolloff = 8 -- keep 8 lines visible above/below cursor (ThePrimagen tip)
vim.opt.sidescrolloff = 8 -- same for horizontal scrolling

-- ── Files & undo ─────────────────────────────────────────────────────────
vim.opt.undofile = true
vim.opt.undolevels = 10000
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undodir
vim.fn.mkdir(undodir, "p")

-- ── Keys & timing ────────────────────────────────────────────────────────
vim.opt.timeout = true
vim.opt.timeoutlen = 500 -- forgiving window for 3-key <leader> chords (space+p+f/s) incl. SSH/tmux jitter; 1000=nvim default, 300=too tight, misses when typed slow
vim.opt.ttimeoutlen = 50 -- key-code wait: 10ms drops <M-1> etc over SSH/tmux jitter; 50 stays snappy

-- ── UI (stock Neovim; colorscheme owns highlights, never this file) ──────
vim.opt.termguicolors = true
vim.opt.signcolumn = "auto" -- appear only when needed
vim.opt.laststatus = 1 -- single statusline per window (stock default)
vim.opt.splitbelow = true -- predictable splits, no viewport jumps
vim.opt.splitright = true
vim.opt.shortmess:append("c") -- no "match X of Y" spam during completion
vim.opt.mouse = "a" -- scrolling/resizing (stock behavior)
vim.opt.pumheight = 0 -- unbounded completion menu (default)

-- ── Performance (large/minified C++ buffers) ─────────────────────────────
vim.opt.ttyfast = true
vim.opt.redrawtime = 1500
vim.opt.synmaxcol = 300 -- don't highlight super long lines (C++ minified/generated)
vim.opt.maxmempattern = 20000

-- ── Integrations ─────────────────────────────────────────────────────────
vim.opt.clipboard = "unnamedplus"
vim.g.autoformat = false -- conform.nvim: formatting is manual (<leader>cF)
-- Silence optional provider warnings (not needed for Rails API + C++ ide)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
