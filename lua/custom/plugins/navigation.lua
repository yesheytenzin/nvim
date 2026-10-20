-- Search & outline: fzf-lua pickers plus a code outline.
-- fzf-lua drives the native fzf binary (already installed), so there is no
-- telescope + fzf-native build step and no plenary dependency for pickers.
return {
  {
    "ibhagwan/fzf-lua",
    cond = function() return vim.fn.executable("fzf") == 1 end,
    cmd = "FzfLua",
    keys = {
      { "<leader><space>", "<cmd>FzfLua files<cr>", desc = "Find Files" },
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>FzfLua git_files<cr>", desc = "Find Git Files" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>,", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>sh", "<cmd>FzfLua helptags<cr>", desc = "Help Pages" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
      { "<leader>sg", "<cmd>FzfLua live_grep<cr>", desc = "Grep" },
      {
        "<leader>sw",
        function() require("fzf-lua").grep_cword() end,
        desc = "Grep word under cursor",
      },
      {
        "<leader>sW",
        function() require("fzf-lua").grep_cWORD() end,
        desc = "Grep WORD under cursor",
      },
      { "<leader>ss", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document Symbols" },
      { "<leader>sS", "<cmd>FzfLua lsp_workspace_symbols<cr>", desc = "Workspace Symbols" },
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
      require("fzf-lua").setup({
        -- fzf-lua's default backdrop paints a full-screen window with the
        -- FzfLuaBackdrop highlight (bg = Black) at 60% blend. On the light
        -- Rose Pine Dawn theme that reads as a black smear around the float;
        -- the border alone is enough separation.
        winopts = { backdrop = false },
      })
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
