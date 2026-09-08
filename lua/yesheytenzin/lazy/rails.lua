-- Rails awareness: vim-rails + rails addon for ruby-lsp
return {
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    init = function()
      -- vim-rails provides :A :R :Emodel :Econtroller :Emigration etc
      -- Recognizes Feedbacks::Create, MutationService nesting, Zeitwerk paths
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "ruby", "eruby" },
        callback = function()
          vim.keymap.set("n", "<leader>ra", "<cmd>A<cr>", { desc = "Rails Alternate (model<->spec)", buffer = true })
          vim.keymap.set("n", "<leader>rA", "<cmd>R<cr>", { desc = "Rails Related", buffer = true })
          vim.keymap.set("n", "<leader>rm", "<cmd>Emigration<cr>", { desc = "Rails Migration" })
          vim.keymap.set("n", "<leader>rc", "<cmd>Econtroller<cr>", { desc = "Rails Controller" })
          vim.keymap.set("n", "<leader>rM", "<cmd>Emodel<cr>", { desc = "Rails Model" })
          vim.keymap.set("n", "<leader>rv", "<cmd>Eview<cr>", { desc = "Rails View" })
        end,
      })
    end,
  },
  -- Optional breadcrumbs / outline.
  {
    "stevearc/aerial.nvim",
    optional = true,
    keys = {
      { "<leader>co", "<cmd>AerialToggle!<cr>", desc = "Outline (Aerial)" },
    },
    opts = {
      layout = { max_width = { 40, 0.2 }, width = nil, min_width = 20 },
      filter_kind = false,
    },
  },
}
