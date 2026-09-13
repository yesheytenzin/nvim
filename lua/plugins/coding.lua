-- Language intelligence in one module: LSP servers, attach keymaps,
-- diagnostics, formatting, and incremental rename. Previously the attach
-- keymaps lived in autocmds.lua and rename in navigation.lua — same
-- concern, now one place.

-- Buffer-local LSP keymaps. Top-level (not inside a spec's config) so they
-- exist from startup, exactly as before: LspAttach can fire for buffers
-- opened before VeryLazy finishes.
-- NOTE: <leader>w (save) and <leader>d (delete) are bare GLOBAL maps, so in
-- LSP buffers vim waits timeoutlen to disambiguate <leader>w vs <leader>ws
-- (and <leader>d vs <leader>ds). That short pause on save/delete in code
-- buffers is the price of keeping Primeagen's ws/ds mnemonics.
local LspGroup = vim.api.nvim_create_augroup("ConfigLsp", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = LspGroup,
  callback = function(e)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = e.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Goto definition")
    map("gD", vim.lsp.buf.declaration, "Goto declaration")
    map("gi", vim.lsp.buf.implementation, "Goto implementation")
    map("gy", vim.lsp.buf.type_definition, "Goto type definition")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
    map("<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbol")
    map("<leader>ls", function() vim.lsp.buf.signature_help() end, "Signature help")
    local client = vim.lsp.get_client_by_id(e.data.client_id)
    if client and client.name == "clangd" then
      map("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "C++ Switch Header/Source")
    end
    -- diagnostics: [d / ]d follow vim convention (prev / next)
    map("[d", function() vim.diagnostic.goto_prev() end, "Prev diagnostic")
    map("]d", function() vim.diagnostic.goto_next() end, "Next diagnostic")
  end,
})

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
  -- Incremental rename preview — RubyMine's inline rename (moved here from
  -- navigation.lua: it is LSP-driven, not file-finding).
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    keys = {
      {
        "<leader>cR",
        function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Rename (inc-rename preview)",
      },
    },
    opts = {},
  },
}
