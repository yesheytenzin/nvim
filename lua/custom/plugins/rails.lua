-- Rails conventions: vim-rails provides :A :R :Emodel :Econtroller :Emigration
-- etc. for model <-> spec <-> controller navigation.
return {
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    config = function()
      -- vim-rails provides :A :R :Emodel :Econtroller :Emigration etc
      -- Recognizes Feedbacks::Create, MutationService nesting, Zeitwerk paths.
      -- Buffer-local maps: without them the maps leak globally after the first
      -- ruby buffer and stack duplicates on every ruby buffer.
      local group = vim.api.nvim_create_augroup("ConfigRailsMaps", { clear = true })
      local function set_maps(buf)
        local opts = { buffer = buf }
        vim.keymap.set(
          "n",
          "<leader>ra",
          "<cmd>A<cr>",
          vim.tbl_extend("force", opts, { desc = "Rails Alternate (model<->spec)" })
        )
        vim.keymap.set("n", "<leader>rA", "<cmd>R<cr>", vim.tbl_extend("force", opts, { desc = "Rails Related" }))
        vim.keymap.set(
          "n",
          "<leader>rm",
          "<cmd>Emigration<cr>",
          vim.tbl_extend("force", opts, { desc = "Rails Migration" })
        )
        vim.keymap.set(
          "n",
          "<leader>rc",
          "<cmd>Econtroller<cr>",
          vim.tbl_extend("force", opts, { desc = "Rails Controller" })
        )
        vim.keymap.set("n", "<leader>rM", "<cmd>Emodel<cr>", vim.tbl_extend("force", opts, { desc = "Rails Model" }))
        vim.keymap.set("n", "<leader>rv", "<cmd>Eview<cr>", vim.tbl_extend("force", opts, { desc = "Rails View" }))
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "ruby", "eruby" },
        callback = function(e)
          set_maps(e.buf)
        end,
      })
      -- The buffer that triggered this load is already ruby/eruby, so its
      -- FileType autocmd has passed; map it directly.
      local ft = vim.bo.filetype
      if ft == "ruby" or ft == "eruby" then
        set_maps(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
