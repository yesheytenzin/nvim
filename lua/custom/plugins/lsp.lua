require("custom.lsp.attach").setup()

return {
  {
    "j-hui/fidget.nvim",
    config = function()
      require("fidget").setup({})
    end,
  },
  {
    "neovim/nvim-lspconfig",
    ft = { "lua", "ruby", "eruby", "c", "cpp", "objc", "objcpp", "zig", "rust", "python", "sh" },
    deps = { "conform.nvim", "mason.nvim", "mason-lspconfig.nvim", "blink.cmp", "fidget.nvim" },
    config = function()
      require("custom.lsp.servers").setup()
    end,
  },
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
    config = function()
      require("inc_rename").setup({})
    end,
  },
}
