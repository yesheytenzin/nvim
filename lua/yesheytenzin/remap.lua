-- Primeagen's core remaps live here; project-specific mappings stay in config/keymaps.lua.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set

map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "J", "mzJ`z", { desc = "Join lines" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })
map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole" })
map("i", "<C-c>", "<Esc>", { desc = "Escape insert mode" })
map("n", "Q", "<nop>", { desc = "Disable Ex mode" })
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
map("n", "<leader>qj", "<cmd>cprev<CR>zz", { desc = "Previous quickfix item" })
map("n", "<leader>qk", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location item" })
map("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Previous location item" })
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word" })
map("n", "<leader>x", function()
  -- Only chmod real files: in netrw/dir buffers % is a directory listing.
  if vim.bo.buftype ~= "" or vim.fn.filereadable(vim.fn.expand("%")) ~= 1 then
    vim.notify("chmod +x: no file in current buffer", vim.log.levels.WARN)
    return
  end
  vim.cmd("!chmod +x %")
end, { silent = true, desc = "Make executable" })
map("n", "<leader><leader>", function()
  -- Sourcing arbitrary buffers (netrw dirs, markdown, ...) errors or stacks
  -- duplicate autocmds. Only source vimscript/lua buffers.
  local ft = vim.bo.filetype
  if ft ~= "lua" and ft ~= "vim" then
    vim.notify("Source: only lua/vim buffers (current: " .. ft .. ")", vim.log.levels.WARN)
    return
  end
  vim.cmd("source %")
end, { desc = "Source current file" })
