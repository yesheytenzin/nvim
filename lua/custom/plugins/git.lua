return {
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git Status (Fugitive)" },
      {
        "<leader>gp",
        function()
          vim.cmd.Git("push")
        end,
        desc = "Git push",
      },
      {
        "<leader>gP",
        function()
          vim.cmd.Git({ "pull", "--rebase" })
        end,
        desc = "Git pull --rebase",
      },
      { "<leader>gu", ":Git push -u origin ", desc = "Git push -u origin (set upstream)" },
    },
    config = function()
      local group = vim.api.nvim_create_augroup("ThePrimeagen_Fugitive", {})

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "fugitive",
        callback = function()
          vim.cmd.wincmd("J")
          vim.api.nvim_win_set_height(0, 15)
        end,
      })

      local function apply_diffget_maps(bufnr)
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set(
          "n",
          "gh",
          "<cmd>diffget //2<cr>",
          vim.tbl_extend("force", opts, { desc = "Take left (ours, //2)" })
        )
        vim.keymap.set(
          "n",
          "gl",
          "<cmd>diffget //3<cr>",
          vim.tbl_extend("force", opts, { desc = "Take right (theirs, //3)" })
        )
      end
      local function remove_diffget_maps(bufnr)
        pcall(vim.keymap.del, "n", "gh", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "gl", { buffer = bufnr })
      end

      vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "diff",
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          if vim.v.option_new == "1" then
            apply_diffget_maps(bufnr)
          else
            remove_diffget_maps(bufnr)
          end
        end,
      })

      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        group = group,
        pattern = "*",
        callback = function()
          if vim.wo.diff then
            apply_diffget_maps(vim.api.nvim_get_current_buf())
          end
        end,
      })
    end,
  },
  {
    "yesheytenzin/mergeui.nvim",
    cmd = {
      "MergeUI",
      "MergeUIClose",
      "MergeUITakeLeft",
      "MergeUITakeRight",
      "MergeUITakeBoth",
      "MergeUITakeNone",
      "MergeUIToggle",
      "MergeUISingle",
      "MergeUITriple",
      "TriMerge",
      "TriMergeClose",
      "RubymineMerge",
    },
    keys = {
      { "<leader>gm", "<cmd>MergeUI<cr>", desc = "Merge: 3-pane (CURRENT | RESULT | INCOMING)" },
    },
    config = function()
      require("mergeui").setup({
        view = "triple",
        keymaps = {
          take_left = "<leader>mh",
          take_right = "<leader>ml",
          take_both = "<leader>mb",
          take_none = "<leader>mx",
          next_conflict = "]c",
          prev_conflict = "[c",
          quit = "<leader>mq",
        },
        show_indicators = true,
      })
    end,
  },
}
