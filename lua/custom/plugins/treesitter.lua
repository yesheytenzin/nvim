local parsers = require("custom.parser_manifest")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    eager = true,
    build = function(path)
      vim.opt.rtp:append(path)
      pcall(vim.cmd, "TSUpdate")
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("ConfigTreesitter", { clear = true })
      local function start(buf)
        if vim.bo[buf].buftype ~= "" then
          return
        end
        if vim.b[buf].bigfile then
          return
        end
        if vim.bo[buf].filetype == "" then
          return
        end
        if pcall(vim.treesitter.start, buf) and vim.bo[buf].filetype == "ruby" then
          vim.bo[buf].syntax = "ruby"
        end
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(e)
          start(e.buf)
        end,
      })
      start(vim.api.nvim_get_current_buf())

      local function ensure_parsers()
        local missing = require("custom.manifest_util").ts_missing(parsers)
        if #missing > 0 then
          require("nvim-treesitter").install(missing)
        end
      end
      if vim.v.vim_did_init == 1 then
        ensure_parsers()
      else
        vim.api.nvim_create_autocmd("User", {
          group = group,
          pattern = "VeryLazy",
          once = true,
          callback = ensure_parsers,
        })
      end
    end,
  },
}
