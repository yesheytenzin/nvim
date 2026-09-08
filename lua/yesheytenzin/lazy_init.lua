local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

if not uv.fs_stat(lazypath) then
  local output = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim:\n" .. output)
  end
end

vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  spec = { { import = "yesheytenzin.lazy" } },
  defaults = { lazy = true, version = false },
  install = { colorscheme = { "rose-pine-dawn" } },
  change_detection = { enabled = false, notify = false },
  checker = { enabled = false, notify = false },
  performance = {
    cache = { enabled = true },
    reset_packpath = true,
    rtp = { disabled_plugins = { "gzip", "matchit", "matchparen", "rplugin", "spellfile", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})
