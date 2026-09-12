-- Formatting and the single LSP configuration used by this plain lazy.nvim setup.
return {
  {
    "stevearc/conform.nvim",
    -- No VeryLazy: autoformat is off and formatting is manual, so loading the
    -- whole formatter stack on every boot is pure overhead. Loads on demand.
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cF",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        desc = "Format buffer",
      },
    },
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
      -- automatic_enable defaults to true, which silently starts an LSP client for
      -- EVERY Mason-installed tool that has a matching lspconfig entry — e.g. a
      -- second, redundant "rubocop" LSP client on top of the RuboCop support
      -- ruby_lsp already runs internally as its own addon. Disable it and enable
      -- servers explicitly so only what's configured above actually attaches.
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
        automatic_enable = false,
      })
      vim.lsp.enable("lua_ls")
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
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    -- No VeryLazy: run_on_start is false so boot load does zero work.
    -- Loads only when explicitly managing tools.
    cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
    opts = {
      ensure_installed = {
        "rubocop", "yamlfmt", "jq", "sql-formatter", "clang-format", "stylua",
        "clangd",
      },
      run_on_start = false,
    },
  },
}
