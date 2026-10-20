return {
  {
    "rose-pine/neovim",
    enabled = vim.fn.filereadable(vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")) == 0,
    eager = true,
    config = function()
      require("rose-pine").setup({
        disable_background = true,
        styles = { italic = false },
      })
      vim.cmd.colorscheme("rose-pine-moon")
    end,
  },
}
