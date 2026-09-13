-- Extra & fallback themes in one module. The ACTIVE theme is omarchy-managed
-- (lazy/theme.lua is a symlink into omarchy state) — never merge it here;
-- that seam is owned externally. lazyvim-compat.lua stays separate too: it
-- exists only because omarchy's template still mentions LazyVim.
return {
  -- Optional extras for :colorscheme (lazy, not loaded)
  { "folke/tokyonight.nvim", lazy = true, priority = 1000 },
  { "rebelot/kanagawa.nvim", lazy = true, priority = 1000 },
  -- Fallback when Omarchy is not installed or has no active theme.
  {
    "rose-pine/neovim",
    name = "rose-pine-fallback",
    enabled = vim.fn.filereadable(vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")) == 0,
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
