-- RubyMine-style "Search Everywhere" polish: faster/accurate finding (fixed: telescope now works without fzf-native)
return {
  -- 1) Make telescope filtering as fast & accurate as RubyMine's index (fzf-native optional)
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = function() return vim.fn.executable("make") == 1 end },
    },
    opts = {
      defaults = {
        sorting_strategy = "descending",
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "bottom", preview_width = 0.55 },
        mappings = {
          i = {
            ["<C-j>"] = function(...)
              return require("telescope.actions").move_selection_next(...)
            end,
            ["<C-k>"] = function(...)
              return require("telescope.actions").move_selection_previous(...)
            end,
            ["<C-q>"] = function(...)
              return require("telescope.actions").send_to_qflist(...)
            end,
            ["<M-q>"] = function(...)
              return require("telescope.actions").send_selected_to_qflist(...)
            end,
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      pcall(require("telescope").load_extension, "fzf")
    end,
    keys = {
      -- core telescope (restored after pure-lazy refactor)
      { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>pg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
      { "<leader>pb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>ph", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>po", "<cmd>Telescope oldfiles<cr>", desc = "Old Files" },
      -- treesitter symbols: instant, accurate, no LSP wait
      { "<leader>pt", "<cmd>Telescope treesitter<cr>", desc = "Symbols (Treesitter) — instant, no LSP" },
      -- Primeagen word-grep group: kept here (not keymaps.lua) so lazy.nvim
      -- registers them BEFORE telescope loads. Eager vim.keymap.set versions
      -- fail on a fresh `nvim .` because telescope isn't on the rtp yet.
      {
        "<leader>ps",
        function()
          local q = vim.fn.input("Grep > ")
          if q == nil or q == "" then return end
          require("telescope.builtin").grep_string({ search = q })
        end,
        desc = "Grep prompt",
      },
      {
        "<leader>pws",
        function()
          require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
        end,
        desc = "Grep word under cursor",
      },
      {
        "<leader>pWs",
        function()
          require("telescope.builtin").grep_string({ search = vim.fn.expand("<cWORD>") })
        end,
        desc = "Grep WORD under cursor",
      },
      {
        "<leader>fd",
        function()
          require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })
        end,
        desc = "Find Files (Buffer Dir)",
      },
      {
        "<leader>fy",
        function()
          local p = vim.fn.expand("%:p")
          vim.fn.setreg("+", p)
          vim.notify("Copied absolute: " .. p)
        end,
        desc = "Copy Absolute Path",
      },
      {
        "<leader>fY",
        function()
          local p = vim.fn.expand("%")
          vim.fn.setreg("+", p)
          vim.notify("Copied relative: " .. p)
        end,
        desc = "Copy Relative Path",
      },
    },
  },
  -- 2) Incremental rename preview — RubyMine's inline rename
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    keys = {
      {
        "<leader>cR",
        function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Rename (inc-rename preview)",
      },
    },
    opts = {},
  },
}
