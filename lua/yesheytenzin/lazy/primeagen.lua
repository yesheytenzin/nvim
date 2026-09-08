-- Primeagen extras: curated high-ROI plugins from ThePrimeagen/init.lua
-- All lazy-loaded — ~0 startup cost

return {
  -- 1) Undotree — <leader>u — Primeagen's most iconic plugin
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo Tree (Primeagen)" },
    },
  },

  -- 2) Trouble — diagnostics list — <leader>tt, [t ]t
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>tt", function() require("trouble").toggle() end, desc = "Trouble toggle" },
      { "[t", function() require("trouble").next({ skip_groups = true, jump = true }) end, desc = "Trouble next" },
      { "]t", function() require("trouble").previous({ skip_groups = true, jump = true }) end, desc = "Trouble prev" },
    },
    opts = {},
  },

  -- 3) Cloak — hide secrets in .env* (Primeagen cloak.lua)
  {
    "laytan/cloak.nvim",
    event = "BufReadPre",
    opts = {
      enabled = true,
      cloak_character = "*",
      highlight_group = "Comment",
      patterns = {
        {
          file_pattern = { ".env*", "wrangler.toml", ".dev.vars" },
          cloak_pattern = "=.+",
        },
      },
    },
  },

  -- 5) Treesitter textobjects — af/if for functions (Primeagen treesitter.lua)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
          },
        },
      })
    end,
  },

  -- 6) Zen-mode — <leader>zz / <leader>zZ (Primeagen zenmode.lua)
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
