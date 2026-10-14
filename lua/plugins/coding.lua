-- Language intelligence in one module: LSP servers, attach keymaps,
-- diagnostics, formatting, and incremental rename.

-- Buffer-local LSP keymaps. Top-level (not inside a spec's config) so they
-- exist from startup: LspAttach can fire for buffers opened before the
-- lspconfig spec has had a chance to load.
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
    -- diagnostics: [d / ]d follow vim convention (prev / next).
    -- jump() replaces the deprecated goto_prev/goto_next (removed in 0.13);
    -- no float popup on jump (was goto's default) — press gl for the float.
    map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
    map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
  end,
})

return {
  {
    "stevearc/conform.nvim",
    -- autoformat is off (vim.g.autoformat = false) and formatting is manual,
    -- so nothing needs the formatter stack on boot. Loads on demand.
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cF",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        desc = "Format buffer",
      },
    },
    config = function()
      require("conform").setup({
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
      })
    end,
  },
  {
    "j-hui/fidget.nvim",
    config = function() require("fidget").setup({}) end,
  },
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    config = function() require("mason").setup() end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    deps = { "mason.nvim" },
    -- automatic_enable defaults to true, which silently starts an LSP client
    -- for EVERY Mason-installed tool that has a matching lspconfig entry —
    -- e.g. a redundant "rubocop" client on top of the RuboCop support ruby_lsp
    -- already runs internally. Disable it and enable servers explicitly below.
    config = function()
      require("mason-lspconfig").setup({
        -- Installed once (scripts/bootstrap.lua, or automatically on first
        -- lspconfig load); every later boot is a local version check, no
        -- download when the packages are cached in Mason. Server list owned
        -- by lua/lsp_manifest.lua — add a row there to add a server. Pinned
        -- versions apply to fresh installs; drift is fixed by bootstrap.sh.
        ensure_installed = vim.tbl_map(function(s)
          return require("install_util").spec(s.lsp, s.version)
        end, require("lsp_manifest").servers),
        automatic_enable = false,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    -- Load only when a file we actually have a server for is opened, not on
    -- every boot. vim.lsp.enable() re-runs FileType detection for already-open
    -- buffers, so the first code file still attaches.
    ft = { "lua", "ruby", "eruby", "c", "cpp", "objc", "objcpp", "zig" },
    deps = { "conform.nvim", "mason.nvim", "mason-lspconfig.nvim", "blink.cmp", "fidget.nvim" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
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
        -- --clang-tidy runs tidy checks on every open C++ file and is the usual
        -- source of lag in large codebases, so it is off by default. Opt back in
        -- per project with a .clangd (Diagnostics:) or a project overlay.
        -- "clangd" resolves via Mason's bin/ (prepended to PATH by mason.nvim)
        -- or a system clangd; no download when already installed.
        cmd = { "clangd", "--background-index", "--background-index-priority=low", "--header-insertion=never" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
      })
      vim.lsp.config("ruby_lsp", {
        capabilities = capabilities,
        init_options = { enabledFeatures = { diagnostics = true } },
      })
      -- zls is not a Mason package: prefer the manual install at
      -- stdpath('data')/zls/bin/zls (fetched by scripts/bootstrap.lua),
      -- fall back to a system zls (e.g. mise). Skip quietly when absent so a
      -- missing Zig toolchain never breaks the other servers.
      local zls_manual = vim.fs.joinpath(vim.fn.stdpath("data"), "zls", "bin", "zls")
      local zls_cmd = vim.fn.executable(zls_manual) == 1 and { zls_manual }
        or vim.fn.executable("zls") == 1 and { "zls" }
        or nil
      if zls_cmd then
        vim.lsp.config("zls", { capabilities = capabilities, cmd = zls_cmd })
      end
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("clangd")
      vim.lsp.enable("ruby_lsp")
      if zls_cmd then
        vim.lsp.enable("zls")
      end
      vim.diagnostic.config({
        -- Virtual text defaults off: on large generated/minified buffers it is a
        -- persistent redraw cost. <leader>ud toggles it on (see keymaps.lua).
        virtual_text = false, signs = true, underline = true, severity_sort = true,
        float = { focusable = false, style = "minimal", border = "rounded", source = "always", header = "", prefix = "" },
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    deps = { "mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
    config = function()
      require("mason-tool-installer").setup({
        -- Prefetched by scripts/bootstrap.lua. run_on_start = false means
        -- normal boots never touch the network here; use :MasonToolsInstall
        -- (or bootstrap) to fetch on a fresh machine. Tool list owned by
        -- lua/lsp_manifest.lua — add a row there to add a tool. Pinned
        -- versions apply to fresh installs; drift is fixed by bootstrap.sh.
        ensure_installed = vim.tbl_map(function(t)
          return { t.name, version = t.version }
        end, require("lsp_manifest").tools),
        run_on_start = false,
      })
    end,
  },
  -- Incremental rename preview — RubyMine's inline rename (LSP-driven).
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
    config = function() require("inc_rename").setup({}) end,
  },
}
