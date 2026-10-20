-- Kickstart UI staples kept after the migration: mini text objects/surround,
-- stock-looking statusline, todo comment highlights, and git hunk signs.
-- Hunk maps live under <leader>gh so <leader>h stays Harpoon.
return {
  {
    "nvim-mini/mini.nvim",
    eager = true,
    config = function()
      require("mini.ai").setup({
        -- Avoid the built-in incremental-selection mappings on Neovim >= 0.12.
        mappings = { around_next = "aa", inside_next = "ii" },
        n_lines = 500,
      })
      require("mini.surround").setup()

      local statusline = require("mini.statusline")
      statusline.setup({ use_icons = vim.g.have_nerd_font })
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return "%2l:%-2v" end
    end,
  },

  {
    "folke/todo-comments.nvim",
    eager = true,
    config = function() require("todo-comments").setup({ signs = false }) end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local gitsigns = require("gitsigns")
      gitsigns.setup({
        signs = {
          add = { text = "+" }, ---@diagnostic disable-line: missing-fields
          change = { text = "~" }, ---@diagnostic disable-line: missing-fields
          delete = { text = "_" }, ---@diagnostic disable-line: missing-fields
          topdelete = { text = "‾" }, ---@diagnostic disable-line: missing-fields
          changedelete = { text = "~" }, ---@diagnostic disable-line: missing-fields
        },
        on_attach = function(bufnr)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "]c", function()
            if vim.wo.diff then
              vim.cmd.normal { "]c", bang = true }
            else
              gitsigns.nav_hunk "next"
            end
          end, "Next git hunk")
          map("n", "[c", function()
            if vim.wo.diff then
              vim.cmd.normal { "[c", bang = true }
            else
              gitsigns.nav_hunk "prev"
            end
          end, "Previous git hunk")

          map("n", "<leader>ghs", gitsigns.stage_hunk, "Stage hunk")
          map("n", "<leader>ghr", gitsigns.reset_hunk, "Reset hunk")
          map("n", "<leader>ghS", gitsigns.stage_buffer, "Stage buffer")
          map("n", "<leader>ghR", gitsigns.reset_buffer, "Reset buffer")
          map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview hunk")
          map("n", "<leader>ghi", gitsigns.preview_hunk_inline, "Preview hunk inline")
          map("n", "<leader>ghb", function() gitsigns.blame_line { full = true } end, "Blame line")
          map("n", "<leader>ghd", gitsigns.diffthis, "Diff against index")
          map("n", "<leader>ghD", function() gitsigns.diffthis "~" end, "Diff against last commit")
          map("n", "<leader>ghq", gitsigns.setqflist, "Hunk quickfix list")
          map("n", "<leader>ght", gitsigns.toggle_current_line_blame, "Toggle line blame")
          map("n", "<leader>ghw", gitsigns.toggle_word_diff, "Toggle word diff")
          map({ "o", "x" }, "ih", gitsigns.select_hunk, "Inside hunk")
        end,
      })
    end,
  },
}
