-- Language intelligence in one module: LSP servers, attach keymaps,
-- diagnostics, formatting, and incremental rename.

-- Buffer-local LSP keymaps. Top-level (not inside a spec's config) so they
-- exist from startup: LspAttach can fire for buffers opened before the
-- lspconfig spec has had a chance to load.
local LspGroup = vim.api.nvim_create_augroup("ConfigLsp", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = LspGroup,
  callback = function(e)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = e.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Goto definition")
    map("gD", vim.lsp.buf.declaration, "Goto declaration")
    map("gI", vim.lsp.buf.implementation, "Goto implementation")
    map("gy", vim.lsp.buf.type_definition, "Goto type definition")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("gK", function() vim.lsp.buf.signature_help() end, "Signature help")
    local client = vim.lsp.get_client_by_id(e.data.client_id)
    if client and client.name == "clangd" then
      map("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "C++ Switch Header/Source")
    end
    -- diagnostics: [d / ]d follow vim convention (prev / next).
    -- jump() replaces the deprecated goto_prev/goto_next (removed in 0.13);
    -- no float popup on jump. Press <leader>cd for the float.
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
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        desc = "Format buffer",
      },
    },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ruby = { "rubocop" }, yaml = { "yamlfmt" }, json = { "jq" },
          c = { "clang_format" }, cpp = { "clang_format" }, lua = { "stylua" },
          sh = { "shfmt" },
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
        -- by lua/custom/lsp_manifest.lua — add a row there to add a server. Pinned
        -- versions apply to fresh installs; drift is fixed by bootstrap.sh.
        ensure_installed = vim.tbl_map(function(s)
          return require("custom.manifest_util").spec(s.lsp, s.version)
        end, require("custom.lsp_manifest").servers),
        automatic_enable = false,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    -- Load only when a file we actually have a server for is opened, not on
    -- every boot. vim.lsp.enable() re-runs FileType detection for already-open
    -- buffers, so the first code file still attaches.
    ft = { "lua", "ruby", "eruby", "c", "cpp", "objc", "objcpp", "zig", "rust", "python", "sh" },
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
      -- ruby_lsp is a mise-managed gem, not a Mason package (see the
      -- `gems` section of lua/custom/lsp_manifest.lua): it has to run under the
      -- Ruby the project pins, and Mason must not provide it — its wrapper puts
      -- the package's gem dir first in GEM_PATH, which shadows the project's
      -- own gems with ABI-mismatched native extensions and kills the boot.
      --
      -- It has to be launched through mise for the same reason. mise puts its
      -- global install dirs on PATH ahead of the shims dir, so a bare
      -- "ruby-lsp" always resolves to the global Ruby (4.0.7 here) even when
      -- the project pins another one (.ruby-version) — the app then boots with
      -- gems compiled for a different Ruby and completions go missing.
      local ruby_lsp_cmd = { "ruby-lsp" }
      if vim.fn.executable "mise" == 1 and vim.fn.executable "sh" == 1 then
        -- Fall back to the plain command when the pinned Ruby has no
        -- ruby-lsp gem installed.
        ruby_lsp_cmd = { "sh", "-c", "mise exec -- ruby-lsp || exec ruby-lsp" }
      end
      vim.lsp.config("ruby_lsp", {
        capabilities = capabilities,
        cmd = ruby_lsp_cmd,
        init_options = {
          enabledFeatures = { diagnostics = true },
          -- ruby-lsp-rails offers to run pending migrations with a
          -- window/showMessageRequest. Neovim renders that as a blocking
          -- vim.ui.select prompt in the middle of the editor, and in a
          -- headless run it hangs the session outright. The migrations are
          -- the developer's call, so turn the prompt off.
          addonSettings = {
            ["Ruby LSP Rails"] = { enablePendingMigrationsPrompt = false },
          },
        },
      })
      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
      })
      vim.lsp.config("pyright", {
        capabilities = capabilities,
      })
      vim.lsp.config("bashls", {
        capabilities = capabilities,
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
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("pyright")
      vim.lsp.enable("bashls")
      if zls_cmd then
        vim.lsp.enable("zls")
      end
      vim.diagnostic.config({
        -- Virtual text defaults off: on large generated/minified buffers it is a
        -- persistent redraw cost. <leader>ud toggles it on (see keymaps.lua).
        virtual_text = false, signs = true, underline = true, severity_sort = true,
        float = { focusable = false, style = "minimal", border = "rounded", source = "always", header = "", prefix = "" },
      })

      -- ruby-lsp answers "receiver.method" completion from its index, and it
      -- only re-indexes the *open* file while handling one of its "combined
      -- requests" (documentSymbol, documentLink, codeLens, foldingRange) --
      -- and only when the last edit may have changed a declaration.
      -- Neovim never issues those requests on its own, so the index keeps the
      -- copy of the file that was on disk when it was opened: a method you
      -- just wrote stays invisible to completion until the file is reopened.
      local refresh_group = vim.api.nvim_create_augroup("ConfigRubyLspIndex", { clear = true })
      local refresh_timer = vim.uv.new_timer()
      local refreshed = {} --- @type table<integer, integer> buffer -> changedtick

      --- Make ruby-lsp re-index the open file.
      ---
      --- Re-opening the document gives the server a fresh copy of it, and a
      --- fresh document has no "last edit" for ruby-lsp to reason about, so
      --- the re-index happens no matter what the last keystroke was. The
      --- notification flushes pending didChange first, so the server indexes
      --- what is in the buffer now, not what it had on disk.
      ---
      --- The documentSymbol request is what makes the server do the re-index;
      --- its response is discarded.
      --- @param bufnr integer
      local function refresh_index(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        local tick = vim.b[bufnr].changedtick
        if refreshed[bufnr] == tick then return end -- buffer is unchanged
        refreshed[bufnr] = tick

        for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
          if client.name == "ruby_lsp" then
            local uri = vim.uri_from_bufnr(bufnr)
            local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
            client:notify("textDocument/didOpen", {
              textDocument = {
                uri = uri,
                languageId = vim.bo[bufnr].filetype,
                version = (vim.lsp.util.buf_versions or {})[bufnr] or 0,
                text = text,
              },
            })
            client:request("textDocument/documentSymbol", { textDocument = { uri = uri } }, function() end, bufnr)
            return
          end
        end
      end

      -- Once typing settles: the method is usually written before it is
      -- called, so this is the moment the index has to catch up.
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = refresh_group,
        pattern = { "*.rb", "*.rake" },
        callback = function(e)
          refresh_timer:stop()
          refresh_timer:start(500, 0, function()
            vim.schedule(function()
              refresh_index(e.buf)
            end)
          end)
        end,
      })

      -- Leaving insert mode and saving cover the case where a definition and
      -- its call are typed in one go: the refresh then happens after both.
      vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
        group = refresh_group,
        pattern = { "*.rb", "*.rake" },
        callback = function(e)
          refresh_index(e.buf)
        end,
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
        -- lua/custom/lsp_manifest.lua — add a row there to add a tool. Pinned
        -- versions apply to fresh installs; drift is fixed by bootstrap.sh.
        ensure_installed = vim.tbl_map(function(t)
          return { t.name, version = t.version }
        end, require("custom.lsp_manifest").tools),
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
        "<leader>cr",
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
