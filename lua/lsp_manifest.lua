-- Single source of truth for language servers and tools.
-- Mirrors lua/treesitter_parsers.lua (which owns the parser list).
-- Add one entry here and every consumer picks it up: mason-lspconfig /
-- mason-tool-installer ensure lists (lua/plugins/coding.lua), headless
-- prefetch (scripts/bootstrap.lua), cache checks (scripts/verify.lua), the
-- :Toolchain status view and save-to-install watcher (lua/toolchain.lua).
--
-- Each server carries both names because they differ: mason-lspconfig wants
-- the lspconfig name ("ruby_lsp"), Mason packages use the registry name
-- ("ruby-lsp"), and verify/:Toolchain check the bin/ executable ("ruby-lsp").
return {
  servers = {
    { lsp = "lua_ls", mason = "lua-language-server", bin = "lua-language-server" },
    { lsp = "ruby_lsp", mason = "ruby-lsp", bin = "ruby-lsp" },
  },
  -- Formatters/linters plus clangd (whose LSP client is configured + enabled
  -- explicitly in coding.lua; only its binary comes from this list).
  tools = { "rubocop", "yamlfmt", "jq", "sql-formatter", "clang-format", "stylua", "clangd" },
}
