return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sR",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Search & replace in project",
      },
    },
    config = function()
      require("grug-far").setup({})
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "<leader>uc",
        function()
          require("treesitter-context").toggle()
        end,
        desc = "Toggle sticky context header",
      },
    },
    config = function()
      require("treesitter-context").setup({ max_lines = 3, multiline_threshold = 1 })
    end,
  },

  {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    config = function()
      local autopairs = require("nvim-autopairs")
      local endwise = require("nvim-autopairs.ts-rule").endwise
      autopairs.setup({ check_ts = true })

      local function block_already_closed()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local indent = vim.fn.indent(row)
        for next_row = row + 1, vim.api.nvim_buf_line_count(0) do
          local text = vim.fn.getline(next_row)
          if text:match("%S") then
            local next_indent = vim.fn.indent(next_row)
            return next_indent > indent or (next_indent == indent and text:match("^%s*end%f[%W]") ~= nil)
          end
        end
        return false
      end

      local rules = vim.list_extend({}, require("nvim-autopairs.rules.endwise-ruby"))
      vim.list_extend(rules, {
        endwise("then$", "end", "lua", nil),
        endwise("function.*%(.*%)$", "end", "lua", nil),
        endwise("%sdo$", "end", "lua", nil),
      })
      for _, rule in ipairs(rules) do
        rule:with_cr(function()
          if block_already_closed() then
            return false
          end
        end)
      end
      autopairs.add_rules(rules)
    end,
  },

  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "eruby", "xml", "javascriptreact", "typescriptreact", "vue", "svelte" },
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>ut", "<cmd>UndotreeToggle<cr>", desc = "Undo Tree (Primeagen)" },
    },
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP References/Definitions",
      },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
    },
    config = function()
      require("trouble").setup({})
    end,
  },

  {
    "laytan/cloak.nvim",
    event = "BufReadPre",
    config = function()
      require("cloak").setup({
        enabled = true,
        cloak_character = "*",
        highlight_group = "Comment",
        patterns = {
          {
            file_pattern = { ".env*", "wrangler.toml", ".dev.vars" },
            cloak_pattern = "=.+",
          },
        },
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    deps = { "nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
      })

      local function select(query)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end
      end
      vim.keymap.set({ "x", "o" }, "af", select("@function.outer"), { desc = "Around function" })
      vim.keymap.set({ "x", "o" }, "if", select("@function.inner"), { desc = "Inside function" })
    end,
  },

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      {
        "<leader>zz",
        function()
          require("zen-mode").setup({ window = { width = 90, options = {} } })
          require("zen-mode").toggle()
          vim.wo.wrap = false
          vim.wo.number = true
          vim.wo.relativenumber = true
        end,
        desc = "Zen mode 90col",
      },
      {
        "<leader>zZ",
        function()
          require("zen-mode").setup({ window = { width = 80, options = {} } })
          require("zen-mode").toggle()
          vim.wo.wrap = false
          vim.wo.number = false
          vim.wo.relativenumber = false
          vim.opt.colorcolumn = "0"
        end,
        desc = "Zen mode 80col (minimal)",
      },
    },
  },
}
