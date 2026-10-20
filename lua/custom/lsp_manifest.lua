-- Single source of truth for language servers and tools.
-- Mirrors lua/custom/parser_manifest.lua (which owns the parser list).
-- Add one entry here and every consumer picks it up: mason-lspconfig /
-- mason-tool-installer ensure lists (lua/custom/plugins/lsp.lua), headless
-- prefetch (scripts/bootstrap.lua), cache checks (scripts/verify.lua), the
-- :Toolchain status view and save-to-install watcher (lua/custom/toolchain.lua).
--
-- Each server carries every name it answers to because they differ:
-- mason-lspconfig wants the lspconfig name ("lua_ls"), Mason packages use
-- the registry name ("lua-language-server"), and verify/:Toolchain check the
-- bin/ executable ("lua-language-server").
--
-- `version` pins the exact Mason registry version (see :Toolchain for the
-- installed ones). Fresh installs get exactly this; scripts/verify.lua fails
-- on drift and scripts/bootstrap.sh reinstalls the pin. Bump a version here
-- to upgrade a tool everywhere.
return {
  servers = {
    { lsp = "lua_ls", mason = "lua-language-server", bin = "lua-language-server", version = "3.19.2" },
    { lsp = "rust_analyzer", mason = "rust-analyzer", bin = "rust-analyzer", version = "2026-10-12" },
    { lsp = "pyright", mason = "pyright", bin = "pyright-langserver", version = "1.1.413" },
    { lsp = "bashls", mason = "bash-language-server", bin = "bash-language-server", version = "5.8.1" },
  },
  -- Ruby gems that mise owns instead of Mason. ruby_lsp runs under the Ruby
  -- the project pins (.ruby-version), so the gem and the native extensions
  -- it ships (prism, rbs) must be installed into that Ruby. A Mason package
  -- is built with one global Ruby and puts its gem dir first in GEM_PATH,
  -- where the ABI-mismatched native extensions are rejected ("Ignoring
  -- prism-1.9.0 because its extensions are not built") and shadow the
  -- project's own copies, so Bundler aborts the boot with GemNotFound.
  -- mise's shim resolves the gem for whichever Ruby is active.
  gems = {
    { lsp = "ruby_lsp", name = "ruby-lsp", bin = "ruby-lsp", version = "0.26.11" },
  },
  -- Formatters/linters plus clangd (whose LSP client is configured + enabled
  -- explicitly in lsp.lua; only its binary comes from this list).
  tools = {
    { name = "rubocop", version = "1.89.0" },
    { name = "yamlfmt", version = "v0.21.0" },
    { name = "jq", version = "jq-1.7" },
    { name = "clang-format", version = "22.1.8" },
    { name = "stylua", version = "v2.5.2" },
    { name = "clangd", version = "22.1.6" },
    { name = "shfmt", version = "v3.13.1" },
  },
  -- zls is not a Mason package (manual install or system). The pin is matched
  -- as a substring of `zls --version` output, so "0.17.0" covers "0.17.0-dev".
  -- Pair with the Zig version in use; zig/zls skew is the classic breakage.
  zls = { version = "0.17.0" },
}
