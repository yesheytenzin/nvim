return {
  {
    "folke/which-key.nvim",
    event = { "VeryLazy" },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer keymaps (which-key)",
      },
    },
    config = function()
      require("which-key").setup({
        preset = "modern",
        delay = 200,
        spec = {
          { "<leader>f", group = "find / file" },
          { "<leader>s", group = "search" },
          { "<leader>c", group = "code" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunk" },
          { "<leader>r", group = "rails" },
          { "<leader>t", group = "test / run" },
          { "<leader>x", group = "lists (diagnostics, quickfix)" },
          { "<leader>u", group = "toggle" },
          { "<leader>q", group = "quit / session" },
          { "<leader>w", group = "window" },
          { "<leader>b", group = "buffer" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>z", group = "zen" },
        },
      })
    end,
  },
}
