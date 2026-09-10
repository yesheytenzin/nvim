-- vim-fugitive: ThePrimeagen style
-- Source: https://github.com/ThePrimeagen/init.lua/blob/master/lua/theprimeagen/lazy/fugitive.lua
-- Mirrors Primeagen exactly: <leader>gs for status, buffer-local push/pull, gu/gh for diffget

return {
  "tpope/vim-fugitive",
  cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
  keys = {
    { "<leader>gs", "<cmd>Git<cr>", desc = "Git Status (Fugitive)" },
    -- gu / gh are set globally in config() below (diffget).
    { "gu", desc = "Diffget //2 (ours)" },
    { "gh", desc = "Diffget //3 (theirs)" },
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
        vim.keymap.set("n", "<leader>p", function()
          vim.cmd.Git("push")
        end, vim.tbl_extend("force", opts, { desc = "Git push" }))

        -- rebase always (Primeagen rule)
        vim.keymap.set("n", "<leader>P", function()
          vim.cmd.Git({ "pull", "--rebase" })
        end, vim.tbl_extend("force", opts, { desc = "Git pull --rebase" }))

        -- push -u origin with prompt for branch name
        vim.keymap.set("n", "<leader>t", ":Git push -u origin ", vim.tbl_extend("force", opts, { desc = "Git push -u origin ..." }))
      end,
    })

    -- Merge-conflict resolution (diffget //2, //3) — scoped to diff windows only.
    -- NOTE: `gu` is Vim's builtin lowercase operator (guiw, guw, ...). Binding it
    -- globally would swallow that operator everywhere, not just during merges, so
    -- these are applied buffer-local and only while 'diff' is actually set on the window.
    local function apply_diffget_maps(bufnr)
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
}
