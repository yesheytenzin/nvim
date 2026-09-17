-- Version control in one module: fugitive (status, push/pull, diffget),
-- diffview (side-by-side working-tree/commit/file-history viewer) plus
-- mergeui (RubyMine-style 3-pane merge). Previously two files, one concern.
return {
  -- vim-fugitive: ThePrimeagen style
  -- Source: https://github.com/ThePrimeagen/init.lua/blob/master/lua/theprimeagen/lazy/fugitive.lua
  -- Mirrors Primeagen exactly: <leader>gs for status, buffer-local push/pull, gu/gh for diffget
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git Status (Fugitive)" },
      -- NOTE: no `gu`/`gh` entries here: a keys entry without an action creates a
      -- GLOBAL placeholder that swallows Vim's builtin `gu` lowercase operator
      -- (guiw, guu, ...) everywhere. diffget maps are buffer-local, applied only
      -- while 'diff' is set (see config() below).
    },
    config = function()
      -- <leader>gs — Primeagen's main toggle (vim.cmd.Git opens :Git status)
      vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git Status (Fugitive)" })

      local group = vim.api.nvim_create_augroup("ThePrimeagen_Fugitive", {})

      -- show fugitive status at bottom as horizontal split (full width)
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "fugitive",
        callback = function()
          vim.cmd.wincmd("J")
          vim.api.nvim_win_set_height(0, 15)
        end,
      })

      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        pattern = "*",
        callback = function()
          if vim.bo.ft ~= "fugitive" then
            return
          end
          local bufnr = vim.api.nvim_get_current_buf()
          local opts = { buffer = bufnr, remap = false, silent = true }
          -- All under <leader>g (git): bare <leader>p would shadow the global
          -- <leader>p* prefix (pf/ps/pg/...) inside fugitive buffers, and bare
          -- <leader>t collides with global <leader>tt (trouble).
          vim.keymap.set("n", "<leader>gp", function()
            vim.cmd.Git("push")
          end, vim.tbl_extend("force", opts, { desc = "Git push" }))

          -- rebase always (Primeagen rule)
          vim.keymap.set("n", "<leader>gP", function()
            vim.cmd.Git({ "pull", "--rebase" })
          end, vim.tbl_extend("force", opts, { desc = "Git pull --rebase" }))

          -- push -u origin with prompt for branch name
          vim.keymap.set("n", "<leader>gt", ":Git push -u origin ", vim.tbl_extend("force", opts, { desc = "Git push -u origin ..." }))
        end,
      })

      -- Merge-conflict resolution (diffget //2, //3) — scoped to diff windows only.
      -- NOTE: `gu` is Vim's builtin lowercase operator (guiw, guw, ...). Binding it
      -- globally would swallow that operator everywhere, not just during merges, so
      -- these are applied buffer-local and only while 'diff' is actually set on the window.
      local function apply_diffget_maps(bufnr)
        -- diffview.nvim sets 'diff' on its own buffers too, but numbers them its
        -- own way, so `diffget //2`/`//3` would target the wrong buffer there.
        -- Skip it; diffview uses do/dp (2-way) and 2do/3do (merge tool) instead.
        if vim.api.nvim_buf_get_name(bufnr):match("^diffview://") then
          return
        end
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "gu", "<cmd>diffget //2<cr>", vim.tbl_extend("force", opts, { desc = "Diffget //2 (ours)" }))
        vim.keymap.set("n", "gh", "<cmd>diffget //3<cr>", vim.tbl_extend("force", opts, { desc = "Diffget //3 (theirs)" }))
      end
      local function remove_diffget_maps(bufnr)
        pcall(vim.keymap.del, "n", "gu", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "gh", { buffer = bufnr })
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

      -- Catch windows that already have 'diff' set when fugitive opens them (e.g. Gdiffsplit).
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
  -- diffview.nvim: single-tabpage, side-by-side diff viewer for the working
  -- tree, arbitrary revs, and a porcelain file history. Complements fugitive
  -- (line-level :Gdiffsplit, staging) with a file-tree-first review surface.
  -- All commands are uppercase and namespaced, so lazy-loading via `keys`/`cmd`
  -- keeps startup free of cost. Only optional dep is nvim-web-devicons, which
  -- is not installed here, so `use_icons` is forced off below.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh", "DiffviewFileHistory", "DiffviewLog" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff: working tree vs index" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diff: close view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diff: branch file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Diff: current file history" },
    },
    opts = {
      -- Smarter intra-line highlighting for changed regions.
      enhanced_diff_hl = true,
      -- Defaults to true and prints a "nvim-web-devicons is required" warning
      -- on every view when devicons is absent. It is absent here.
      use_icons = false,
      -- Keep the file panel on the left; diff2_horizontal splits stacked.
      view = {
        default = { layout = "diff2_horizontal" },
        file_history = { layout = "diff2_horizontal" },
      },
      -- diffview installs BUFFER-LOCAL leader maps in its views/panels, so a
      -- few of its defaults shadow this config's globals inside diff buffers:
      --   <leader>e  -> focus file panel   shadows netrw (<leader>e)
      --   <leader>ca -> choose all         shadows LSP code action (<leader>ca)
      --   <leader>co -> choose ours        shadows Aerial outline (<leader>co)
      -- Drop those three; keep diffview's non-colliding <leader>b/ct/cb/cO/...
      -- Conflict resolution still works via diff-mode natives (do/dp in a
      -- 2-way diff, 2do/3do in the merge tool).
      keymaps = {
        view = {
          ["<leader>e"] = false,
          ["<leader>ca"] = false,
          ["<leader>co"] = false,
          -- Re-home "focus file panel" onto a collision-free git-namespaced key.
          ["<leader>ge"] = "<cmd>DiffviewFocusFiles<cr>",
        },
        file_panel = {
          ["<leader>e"] = false,
          ["<leader>ge"] = "<cmd>DiffviewFocusFiles<cr>",
        },
        file_history_panel = {
          ["<leader>e"] = false,
          ["<leader>ge"] = "<cmd>DiffviewFocusFiles<cr>",
        },
      },
    },
    config = function(_, opts)
      require("diffview").setup(opts)
    end,
  },
  -- mergeui.nvim: RubyMine-style 3-pane merge (CURRENT | RESULT | INCOMING) — renamed from tri-merge
  {
    "yesheytenzin/mergeui.nvim",
    cmd = { "MergeUI", "MergeUIClose", "MergeUITakeLeft", "MergeUITakeRight", "MergeUITakeBoth", "MergeUITakeNone", "MergeUIToggle", "MergeUISingle", "MergeUITriple", "TriMerge", "TriMergeClose", "RubymineMerge" },
    keys = {
      { "<leader>gm", "<cmd>MergeUI<cr>", desc = "Merge: 3-pane (CURRENT | RESULT | INCOMING)" },
      -- NOTE: no bare `]c`/`[c` entries: a keys entry without an action creates a
      -- GLOBAL placeholder that swallows the builtin diff motions ]c/[c
      -- everywhere. Conflict navigation stays buffer-local via opts.keymaps.
    },
    opts = {
      view = "triple", -- "triple" (CURRENT|RESULT|INCOMING) or "single" (RESULT only) -- toggle with <leader>mt or :MergeUIToggle,
      keymaps = {
        take_left = "<leader>mh", -- >> CURRENT
        take_right = "<leader>ml", -- << INCOMING
        take_both = "<leader>mb",
        take_none = "<leader>mx",
        next_conflict = "]c",
        prev_conflict = "[c",
        quit = "<leader>mq",
      },
      show_indicators = true,
    },
    config = function(_, opts)
      require("mergeui").setup(opts)
    end,
  },
}
