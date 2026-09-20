-- Search & outline: fzf-lua pickers plus a code outline.
-- fzf-lua drives the native fzf binary (already installed), so there is no
-- telescope + fzf-native build step and no plenary dependency for pickers.
return {
  {
    "ibhagwan/fzf-lua",
    cond = function() return vim.fn.executable("fzf") == 1 end,
    cmd = "FzfLua",
    keys = {
      { "<leader>pf", "<cmd>FzfLua files<cr>", desc = "Find Files" },
      { "<leader>pg", "<cmd>FzfLua live_grep<cr>", desc = "Grep" },
      { "<leader>pb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>ph", "<cmd>FzfLua helptags<cr>", desc = "Help" },
      { "<leader>po", "<cmd>FzfLua oldfiles<cr>", desc = "Old Files" },
      { "<leader>pt", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Symbols (LSP)" },
      -- Primeagen word-grep group: lazy keys keep fzf-lua unloaded until use.
      {
        "<leader>ps",
        function()
          local q = vim.fn.input("Grep > ")
          if q == nil or q == "" then return end
          require("fzf-lua").grep({ search = q })
        end,
        desc = "Grep prompt",
      },
      {
        "<leader>pws",
        function() require("fzf-lua").grep_cword() end,
        desc = "Grep word under cursor",
      },
      {
        "<leader>pWs",
        function() require("fzf-lua").grep_cWORD() end,
        desc = "Grep WORD under cursor",
      },
      {
        "<leader>fd",
        function() require("fzf-lua").files({ cwd = vim.fn.expand("%:p:h") }) end,
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
    config = function()
      require("fzf-lua").setup({})
    end,
  },

  -- Outline / breadcrumbs (not Rails-specific).
  {
    "stevearc/aerial.nvim",
    keys = {
      { "<leader>co", "<cmd>AerialToggle!<cr>", desc = "Outline (Aerial)" },
    },
    config = function()
      require("aerial").setup({
        layout = { max_width = { 40, 0.2 }, width = nil, min_width = 20 },
        filter_kind = false,
      })
    end,
  },
}
