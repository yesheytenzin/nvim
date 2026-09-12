-- Rails awareness: vim-rails + rails addon for ruby-lsp
return {
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    init = function()
      -- vim-rails provides :A :R :Emodel :Econtroller :Emigration etc
      -- Recognizes Feedbacks::Create, MutationService nesting, Zeitwerk paths
      -- Augroup + buffer-local: without these the maps leak globally after the
      -- first ruby buffer and the autocmd stacks duplicates on every reload.
      local group = vim.api.nvim_create_augroup("YesheytenzinRailsMaps", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "ruby", "eruby" },
        callback = function(e)
          local opts = { buffer = e.buf }
          vim.keymap.set("n", "<leader>ra", "<cmd>A<cr>", vim.tbl_extend("force", opts, { desc = "Rails Alternate (model<->spec)" }))
          vim.keymap.set("n", "<leader>rA", "<cmd>R<cr>", vim.tbl_extend("force", opts, { desc = "Rails Related" }))
          vim.keymap.set("n", "<leader>rm", "<cmd>Emigration<cr>", vim.tbl_extend("force", opts, { desc = "Rails Migration" }))
          vim.keymap.set("n", "<leader>rc", "<cmd>Econtroller<cr>", vim.tbl_extend("force", opts, { desc = "Rails Controller" }))
          vim.keymap.set("n", "<leader>rM", "<cmd>Emodel<cr>", vim.tbl_extend("force", opts, { desc = "Rails Model" }))
          vim.keymap.set("n", "<leader>rv", "<cmd>Eview<cr>", vim.tbl_extend("force", opts, { desc = "Rails View" }))
        end,
      })
    end,
  },
  -- Optional breadcrumbs / outline.
  {
    "stevearc/aerial.nvim",
    -- No event: keys-only loading keeps it out of the boot path entirely.
    keys = {
      { "<leader>co", "<cmd>AerialToggle!<cr>", desc = "Outline (Aerial)" },
    },
    opts = {
      layout = { max_width = { 40, 0.2 }, width = nil, min_width = 20 },
      filter_kind = false,
    },
  },
}
