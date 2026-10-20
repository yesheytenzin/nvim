return {
  {
    "stevearc/conform.nvim",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        desc = "Format buffer",
      },
    },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ruby = { "rubocop" },
          yaml = { "yamlfmt" },
          json = { "jq" },
          c = { "clang_format" },
          cpp = { "clang_format" },
          lua = { "stylua" },
          sh = { "shfmt" },
        },
        formatters = { rubocop = { timeout_ms = 5000 } },
        format_on_save = function()
          if vim.g.autoformat == false then
            return nil
          end
          return { timeout_ms = 5000, lsp_fallback = true }
        end,
        log_level = vim.log.levels.WARN,
      })
    end,
  },
}
