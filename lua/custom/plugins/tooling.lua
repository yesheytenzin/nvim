return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    config = function()
      require("mason").setup()
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    deps = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_map(function(server)
          return require("custom.manifest_util").spec(server.lsp, server.version)
        end, require("custom.lsp_manifest").servers),
        automatic_enable = false,
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    deps = { "mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = vim.tbl_map(function(tool)
          return { tool.name, version = tool.version }
        end, require("custom.lsp_manifest").tools),
        run_on_start = false,
      })
    end,
  },
}
