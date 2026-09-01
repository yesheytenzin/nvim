-- bootstrap lazy.nvim as package manager + load configs in correct order
-- leader must be set before lazy (also set in config/lazy.lua, keep synced)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
require("config.options")
require("config.lazy")
require("config.autocmds")
require("config.keymaps")
pcall(require, "config.theme")
