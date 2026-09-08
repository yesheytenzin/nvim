-- Formatting and the single LSP configuration used by this plain lazy.nvim setup.
return {
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
      formatters_by_ft = {
        ruby = { "rubocop" }, yaml = { "yamlfmt" }, json = { "jq" }, sql = { "sql_formatter" },
        c = { "clang_format" }, cpp = { "clang_format" }, lua = { "stylua" },
      },
      formatters = { rubocop = { timeout_ms = 5000 } },
      format_on_save = function()
        if vim.g.autoformat == false then return nil end
        return { timeout_ms = 5000, lsp_fallback = true }
      end,
      log_level = vim.log.levels.WARN,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      "stevearc/conform.nvim", "mason-org/mason.nvim", "mason-org/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp", "j-hui/fidget.nvim",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      require("fidget").setup({})
      require("mason").setup()
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = { Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
          format = { enable = true, defaultConfig = { indent_style = "space", indent_size = "2" } },
        } },
      })
      vim.lsp.config("clangd", {
        capabilities = capabilities,
        cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
      })
      vim.lsp.config("ruby_lsp", {
        capabilities = capabilities,
        init_options = { enabledFeatures = { diagnostics = true } },
      })
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
      })
      vim.lsp.enable("clangd")
      vim.lsp.enable("ruby_lsp")
      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2, source = "if_many" }, signs = true, underline = true, severity_sort = true,
        float = { focusable = false, style = "minimal", border = "rounded", source = "always", header = "", prefix = "" },
      })
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        "rubocop", "yamlfmt", "jq", "sql-formatter", "clang-format", "stylua",
      },
      run_on_start = false,
    },
  },
}
