return {
  {
    "nvim-mini/mini.nvim",
    eager = true,
    config = function()
      require("mini.ai").setup({
        mappings = { around_next = "aa", inside_next = "ii" },
        n_lines = 500,
      })
      require("mini.surround").setup()

      local indentscope = require("mini.indentscope")
      indentscope.setup({
        symbol = "│",
        options = { try_as_border = true },
        draw = { delay = 50, animation = indentscope.gen_animation.none() },
        mappings = { object_scope = "", object_scope_with_border = "", goto_top = "[i", goto_bottom = "]i" },
      })
      vim.api.nvim_create_autocmd({ "FileType", "TermOpen" }, {
        group = vim.api.nvim_create_augroup("ConfigIndentscope", { clear = true }),
        callback = function(e)
          local ft = vim.bo[e.buf].filetype
          if vim.bo[e.buf].buftype ~= "" or ft == "help" or ft == "netrw" or ft == "fugitive" then
            vim.b[e.buf].miniindentscope_disable = true
          end
        end,
      })

      require("mini.cursorword").setup({ delay = 100 })
      require("mini.tabline").setup({ tabpage_section = "right" })

      local icons = require("mini.icons")
      icons.setup()
      icons.mock_nvim_web_devicons()

      local function path_from_launch_dir()
        local name = vim.api.nvim_buf_get_name(0)
        if name == "" then
          return "[No Name]"
        end
        local path = vim.fs.relpath(vim.fn.getcwd(-1, -1), name) or vim.fn.fnamemodify(name, ":~")
        return (path:gsub("%%", "%%%%"))
      end

      local statusline = require("mini.statusline")
      statusline.setup({
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = statusline.section_mode({ trunc_width = math.huge })
            local diagnostics = statusline.section_diagnostics({ trunc_width = 0, icon = "" })
            return statusline.combine_groups({
              { hl = mode_hl, strings = { mode } },
              {
                hl = "MiniStatuslineFilename",
                strings = { path_from_launch_dir() .. "%{&modified ? ' [+]' : ''}" },
              },
              "%=",
              { hl = "MiniStatuslineFilename", strings = { diagnostics } },
              { hl = mode_hl, strings = { "%l:%v" } },
            })
          end,
          inactive = function()
            return "%#MiniStatuslineInactive# " .. path_from_launch_dir() .. "%="
          end,
        },
      })
    end,
  },

  {
    "folke/todo-comments.nvim",
    eager = true,
    config = function()
      require("todo-comments").setup({ signs = false })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local gitsigns = require("gitsigns")
      gitsigns.setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "]h", function()
            gitsigns.nav_hunk("next")
          end, "Next git hunk")
          map("n", "[h", function()
            gitsigns.nav_hunk("prev")
          end, "Previous git hunk")

          map("n", "<leader>ghs", gitsigns.stage_hunk, "Stage hunk")
          map("n", "<leader>ghr", gitsigns.reset_hunk, "Reset hunk")
          map("n", "<leader>ghS", gitsigns.stage_buffer, "Stage buffer")
          map("n", "<leader>ghR", gitsigns.reset_buffer, "Reset buffer")
          map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview hunk")
          map("n", "<leader>ghi", gitsigns.preview_hunk_inline, "Preview hunk inline")
          map("n", "<leader>ghb", function()
            gitsigns.blame_line({ full = true })
          end, "Blame line")
          map("n", "<leader>ghd", gitsigns.diffthis, "Diff against index")
          map("n", "<leader>ghD", function()
            gitsigns.diffthis("~")
          end, "Diff against last commit")
          map("n", "<leader>ghq", gitsigns.setqflist, "Hunk quickfix list")
          map("n", "<leader>ght", gitsigns.toggle_current_line_blame, "Toggle line blame")
          map("n", "<leader>ghw", gitsigns.toggle_word_diff, "Toggle word diff")
          map({ "o", "x" }, "ih", gitsigns.select_hunk, "Inside hunk")
        end,
      })
    end,
  },
}
