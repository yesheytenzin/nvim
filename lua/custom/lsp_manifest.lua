return {
  servers = {
    { lsp = "lua_ls", mason = "lua-language-server", bin = "lua-language-server", version = "3.19.2" },
    { lsp = "rust_analyzer", mason = "rust-analyzer", bin = "rust-analyzer", version = "2026-10-12" },
    { lsp = "pyright", mason = "pyright", bin = "pyright-langserver", version = "1.1.413" },
    { lsp = "bashls", mason = "bash-language-server", bin = "bash-language-server", version = "5.8.1" },
  },
  gems = {
    { lsp = "ruby_lsp", name = "ruby-lsp", bin = "ruby-lsp", version = "0.26.11" },
  },
  tools = {
    { name = "rubocop", version = "1.89.0" },
    { name = "yamlfmt", version = "v0.21.0" },
    { name = "jq", version = "jq-1.7" },
    { name = "clang-format", version = "22.1.8" },
    { name = "stylua", version = "v2.5.2" },
    { name = "clangd", version = "22.1.6" },
    { name = "shfmt", version = "v3.13.1" },
  },
  zls = { version = "0.17.0" },
}
