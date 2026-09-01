-- C++ polish: ensure parsers + clangd settings for Rails API + C++ stack
return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    opts = { ensure_installed = { "c", "cpp", "cmake", "make", "ruby", "yaml", "json", "bash", "regex", "sql" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
          filetypes = { "c", "cpp", "objc", "objcpp" },
        },
      },
    },
  },
}
