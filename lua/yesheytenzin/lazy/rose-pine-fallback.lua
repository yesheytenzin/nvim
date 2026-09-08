-- Use Rose Pine Moon when Omarchy is not installed or has no active theme.
local omarchy_theme = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

return {
  {
    "rose-pine/neovim",
    name = "rose-pine-fallback",
    enabled = vim.fn.filereadable(omarchy_theme) == 0,
    lazy = false,
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        disable_background = true,
        styles = { italic = false },
      })
      vim.cmd.colorscheme("rose-pine-moon")
    end,
  },
}
