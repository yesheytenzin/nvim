-- Editor enhancements, Primeagen-curated (ThePrimeagen/init.lua):
-- undo tree, diagnostics list, secret cloaking, textobjects, zen mode.
-- Named by role, not author. All trigger-loaded — ~0 startup cost.

return {
  -- 1) Undotree — <leader>ut — Primeagen's most iconic plugin (ut, not bare u:
  -- bare <leader>u would collide with the <leader>ud diagnostics toggle)
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>ut", "<cmd>UndotreeToggle<cr>", desc = "Undo Tree (Primeagen)" },
    },
  },

  -- 2) Trouble diagnostics, symbols, references, and list views.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
      {
        "<leader>cS",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP References/Definitions",
      },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List" },
    },
    config = function() require("trouble").setup({}) end,
  },

  -- 3) Cloak — hide secrets in .env* (Primeagen cloak.lua)
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

  -- 4) Treesitter textobjects — af/if for functions (Primeagen treesitter.lua)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    deps = { "nvim-treesitter" },
    config = function()
      -- nvim-treesitter main dropped the `select.keymaps` option; define the
      -- mappings explicitly against the select module.
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
      })

      local function select(query)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end
      end
      vim.keymap.set({ "x", "o" }, "af", select "@function.outer", { desc = "Around function" })
      vim.keymap.set({ "x", "o" }, "if", select "@function.inner", { desc = "Inside function" })
    end,
  },

  -- 5) Zen-mode — <leader>zz / <leader>zZ (Primeagen zenmode.lua)
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
