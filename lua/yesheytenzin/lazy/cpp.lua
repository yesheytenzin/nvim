-- C++ polish: ensure parsers + clangd settings for Rails API + C++ stack
return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    init = function()
      local parsers = { "c", "cpp", "cmake", "make", "ruby", "yaml", "json", "bash", "regex", "sql" }
      local group = vim.api.nvim_create_augroup("YesheytenzinTreesitter", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        group = group,
        callback = function(e)
          if vim.bo[e.buf].buftype ~= "" then return end
          if vim.b[e.buf].bigfile then return end -- syntax already off; skip parse cost
          pcall(vim.treesitter.start, e.buf)
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VeryLazy",
        once = true,
        callback = function() require("nvim-treesitter").install(parsers) end,
      })
    end,
  },
}
