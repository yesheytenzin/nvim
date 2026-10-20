return {
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    config = function()
      local group = vim.api.nvim_create_augroup("ConfigRailsMaps", { clear = true })
      local function set_maps(buf)
        for lhs, spec in pairs({
          ["<leader>ra"] = { "A", "Rails alternate (model <-> spec)" },
          ["<leader>rr"] = { "R", "Rails related" },
          ["<leader>rm"] = { "Emodel", "Rails model" },
          ["<leader>rc"] = { "Econtroller", "Rails controller" },
          ["<leader>rv"] = { "Eview", "Rails view" },
          ["<leader>rd"] = { "Emigration", "Rails db migration" },
        }) do
          vim.keymap.set("n", lhs, "<cmd>" .. spec[1] .. "<cr>", { buffer = buf, desc = spec[2] })
        end
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "ruby", "eruby" },
        callback = function(e)
          set_maps(e.buf)
        end,
      })
      local ft = vim.bo.filetype
      if ft == "ruby" or ft == "eruby" then
        set_maps(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
