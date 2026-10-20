-- Fallback theme module. The ACTIVE theme is omarchy-managed (read from
-- ~/.local/state/omarchy/current/theme/neovim.lua) and handled by
-- lua/custom/omarchy_theme.lua — never merge it here; that seam is owned externally.
return {
  -- Fallback when Omarchy is not installed or has no active theme.
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
