vim.g.mapleader = " " -- also set in init.lua -- <Space> is leader (telescope <leader>ff etc)
vim.g.maplocalleader = "\\" -- also set in init.lua
if vim.loader then vim.loader.enable() end
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Pure lazy.nvim as package manager (no LazyVim distribution)
-- All plugins are now explicit in lua/plugins/*.lua
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = true, -- lazy true with explicit events per plugin (keeps startup fast)
    version = false,
  },
  ui = { border = "none" },
  install = { colorscheme = { "tokyonight" } },
  change_detection = { enabled = false, notify = false },
  checker = { enabled = false, notify = false },
  performance = {
    cache = { enabled = true },
    reset_packpath = true,
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "rplugin",
        "spellfile",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "vimball",
        "vimballPlugin",
        "getscript",
        "getscriptPlugin",
        "2html_plugin",
        "synmenu",
        "optwin",
      },
    },
  },
})
