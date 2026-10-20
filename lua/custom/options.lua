vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 200

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.undofile = true
vim.opt.undolevels = 10000
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undodir
vim.fn.mkdir(undodir, "p")

vim.opt.timeout = true
vim.opt.timeoutlen = 350
vim.opt.ttimeoutlen = 50

vim.g.have_nerd_font = true
vim.opt.fillchars = { eob = " ", fold = " " }
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.termguicolors = true
vim.opt.signcolumn = "auto"
vim.opt.splitbelow = true
vim.opt.laststatus = 2
vim.opt.splitright = true
vim.opt.shortmess:append("c")
vim.opt.mouse = "a"
vim.opt.pumheight = 0

vim.opt.redrawtime = 1500
vim.opt.synmaxcol = 300
vim.opt.maxmempattern = 20000

vim.opt.clipboard = "unnamedplus"
vim.g.autoformat = false
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
