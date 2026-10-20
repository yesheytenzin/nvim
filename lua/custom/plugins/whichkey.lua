-- which-key: popup showing pending keystrokes (<leader>, g, z, ", ', `, c, v in visual...)
-- All keymaps already carry `desc`, so this just works. Groups below give
-- the <leader> prefixes friendly names in the popup.
return {
  {
    "folke/which-key.nvim",
    event = { "VeryLazy" },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer keymaps (which-key)",
      },
    },
    config = function()
      require("which-key").setup({
        preset = "modern",
        delay = 200,
        spec = {
          { "<leader>f", group = "File" },
          { "<leader>c", group = "Code" },
          { "<leader>q", group = "Session/Quit" },
          { "<leader>g", group = "Git" },
          { "<leader>gh", group = "Git Hunk" },
          { "<leader>r", group = "Rails/Refactor" },
          { "<leader>m", group = "Merge" },
          { "<leader>u", group = "UI/Toggle" },
          { "<leader>s", group = "Search" },
          { "<leader>x", group = "Diagnostics/Quickfix" },
          { "<leader>w", group = "Windows" },
          { "<leader>z", group = "Zen" },
        },
      })
    end,
  },
}
