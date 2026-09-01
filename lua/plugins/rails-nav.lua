-- Rails convention navigation: User <-> users table <-> User spec <-> factory <-> controller
return {
  {
    "rgroli/other.nvim",
    event = "VeryLazy",
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
      style = { border = "none" },
    },
    keys = {
      { "<leader>ro", "<cmd>Other<cr>", desc = "Other (Rails alternate)" },
      { "<leader>rO", "<cmd>OtherVSplit<cr>", desc = "Other vsplit" },
      { "<leader>rp", "<cmd>OtherClear<cr>", desc = "Other clear" },
    },
  },
}
