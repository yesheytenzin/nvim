-- Rails in one module: vim-rails commands plus convention navigation
-- (other.nvim: model <-> spec <-> factory <-> controller). Previously split
-- across rails.lua/rails-nav.lua with no seam between them. The outline
-- (aerial) is not Rails-specific, so it lives in navigation.lua.
return {
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    init = function()
      -- vim-rails provides :A :R :Emodel :Econtroller :Emigration etc
      -- Recognizes Feedbacks::Create, MutationService nesting, Zeitwerk paths
      -- Augroup + buffer-local: without these the maps leak globally after the
      -- first ruby buffer and the autocmd stacks duplicates on every reload.
      local group = vim.api.nvim_create_augroup("ConfigRailsMaps", { clear = true })
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
  {
    "rgroli/other.nvim",
    -- No event: invoked manually via keys only, so skip the VeryLazy load.
    config = function(_, opts)
      require("other-nvim").setup(opts)
    end,
    opts = {
      mappings = {
        -- Rails model <-> spec <-> factory
        "rails",
        -- Custom overrides for app/services, queries, serializers etc
        {
          pattern = "/app/models/(.*).rb",
          target = {
            { target = "/spec/models/%1_spec.rb", context = "spec" },
            { target = "/spec/factories/%1s.rb", context = "factory" },
            { target = "/app/controllers/%1s_controller.rb", context = "controller" },
            { target = "/db/migrate/*%1*.rb", context = "migration" },
          },
        },
        {
          pattern = "/app/services/(.*).rb",
          target = {
            { target = "/spec/services/%1_spec.rb", context = "spec" },
            { target = "/app/models/%1.rb", context = "model" },
          },
        },
      },
      transformers = { "lowercase" },
    },
    keys = {
      { "<leader>ro", "<cmd>Other<cr>", desc = "Other (Rails alternate)" },
      { "<leader>rO", "<cmd>OtherVSplit<cr>", desc = "Other vsplit" },
      { "<leader>rp", "<cmd>OtherClear<cr>", desc = "Other clear" },
    },
  },
}
