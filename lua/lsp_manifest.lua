-- Single source of truth for language servers and tools.
-- Mirrors lua/treesitter_parsers.lua (which owns the parser list).
-- Add one entry here and every consumer picks it up: mason-lspconfig /
-- mason-tool-installer ensure lists (lua/plugins/coding.lua), headless
-- prefetch (scripts/bootstrap.lua), cache checks (scripts/verify.lua), the
-- :Toolchain status view and save-to-install watcher (lua/toolchain.lua).
--
-- Each server carries every name it answers to because they differ:
-- mason-lspconfig wants the lspconfig name ("ruby_lsp"), Mason packages use
-- the registry name ("ruby-lsp"), and verify/:Toolchain check the bin/
-- executable ("ruby-lsp").
--
-- `version` pins the exact Mason registry version (see :Toolchain for the
-- installed ones). Fresh installs get exactly this; scripts/verify.lua fails
-- on drift and scripts/bootstrap.sh reinstalls the pin. Bump a version here
-- to upgrade a tool everywhere.
return {
  servers = {
    { lsp = "lua_ls", mason = "lua-language-server", bin = "lua-language-server", version = "3.19.2" },
    { lsp = "ruby_lsp", mason = "ruby-lsp", bin = "ruby-lsp", version = "0.26.11" },
    { lsp = "rust_analyzer", mason = "rust-analyzer", bin = "rust-analyzer", version = "2026-10-12" },
  },
  -- Formatters/linters plus clangd (whose LSP client is configured + enabled
  -- explicitly in coding.lua; only its binary comes from this list).
  tools = {
    { name = "rubocop", version = "1.89.0" },
    { name = "yamlfmt", version = "v0.21.0" },
    { name = "jq", version = "jq-1.7" },
    { name = "clang-format", version = "22.1.8" },
    { name = "stylua", version = "v2.5.2" },
    { name = "clangd", version = "22.1.6" },
  },
  -- zls is not a Mason package (manual install or system). The pin is matched
  -- as a substring of `zls --version` output, so "0.17.0" covers "0.17.0-dev".
  -- Pair with the Zig version in use; zig/zls skew is the classic breakage.
  zls = { version = "0.17.0" },
}
