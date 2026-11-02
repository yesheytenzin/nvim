local M = {}

function M.setup()
  -- Lazy-safe: blink.cmp is InsertEnter-lazy, don't force it early on FileType.
  local ok_blink, blink = pcall(require, "blink.cmp")
  local capabilities = ok_blink and blink.get_lsp_capabilities()
    or vim.lsp.protocol.make_client_capabilities()
  local ruby = require("custom.lsp.ruby")

  vim.lsp.config("lua_ls", {
    capabilities = capabilities,
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
        format = { enable = true, defaultConfig = { indent_style = "space", indent_size = "2" } },
      },
    },
  })
  vim.lsp.config("clangd", {
    capabilities = capabilities,
    cmd = { "clangd", "--background-index", "--background-index-priority=low", "--header-insertion=never" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
  })
  vim.lsp.config("ruby_lsp", {
    capabilities = capabilities,
    cmd = ruby.command,
    -- 0 flooded the server on every keystroke and slowed indexing.
    -- 150ms is the standard sweet spot for responsiveness vs. load.
    flags = { debounce_text_changes = 150 },
    init_options = {
      enabledFeatures = { diagnostics = true },
      addonSettings = {
        ["Ruby LSP Rails"] = { enablePendingMigrationsPrompt = false },
      },
    },
  })
  vim.lsp.config("rust_analyzer", { capabilities = capabilities })
  vim.lsp.config("pyright", { capabilities = capabilities })
  vim.lsp.config("bashls", { capabilities = capabilities })

  local manual_zls = vim.fs.joinpath(vim.fn.stdpath("data"), "zls", "bin", "zls")
  local zls_cmd = vim.fn.executable(manual_zls) == 1 and { manual_zls }
    or vim.fn.executable("zls") == 1 and { "zls" }
    or nil
  if zls_cmd then
    vim.lsp.config("zls", { capabilities = capabilities, cmd = zls_cmd })
  end

  for _, name in ipairs({ "lua_ls", "clangd", "ruby_lsp", "rust_analyzer", "pyright", "bashls" }) do
    vim.lsp.enable(name)
  end
  if zls_cmd then
    vim.lsp.enable("zls")
  end

  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })
  -- Incremental sync keeps the server fresh; no fake didOpen loop needed.
end

return M
