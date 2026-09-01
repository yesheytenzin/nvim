-- Formatting/linting/diagnostics: Rails API + C++ optimized
return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      formatters_by_ft = {
        ruby = { "rubocop" },
        yaml = { "yamlfmt" },
        json = { "jq" },
        sql = { "sql_formatter" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        lua = { "stylua" },
      },
      formatters = {
        rubocop = { timeout_ms = 5000 },
      },
      format_on_save = function(bufnr)
        if vim.g.autoformat == false then return nil end
        return { timeout_ms = 5000, lsp_fallback = true }
      end,
      log_level = vim.log.levels.WARN,
    },
  },
  -- Diagnostics: single source of truth (was duplicated in options.lua)
  {
    "neovim/nvim-lspconfig",
    opts = function()
      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2, source = "if_many" },
        signs = true,
        underline = true,
        severity_sort = true,
        float = { border = "none", source = "always" },
      })
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "rubocop", "yamlfmt", "jq", "sql-formatter", "clang-format", "stylua", "lua-language-server" } },
  },
  -- Primeagen 1 + 3 + 4: mason-lspconfig handlers pattern with lua_ls config
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "lua_ls" },
      handlers = {
        -- default handler
        function(server_name)
          require("lspconfig")[server_name].setup({})
        end,
        -- Primeagen lua_ls: LuaJIT, vim globals, workspace library, 2-space format
        ["lua_ls"] = function()
          require("lspconfig").lua_ls.setup({
            settings = {
              Lua = {
                runtime = { version = "LuaJIT" },
                diagnostics = { globals = { "vim" } },
                workspace = {
                  library = vim.api.nvim_get_runtime_file("", true),
                  checkThirdParty = false,
                },
                format = {
                  enable = true,
                  defaultConfig = {
                    indent_style = "space",
                    indent_size = "2",
                  },
                },
              },
            },
          })
        end,
      },
    },
  },
}
