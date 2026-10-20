vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set

for _, lhs in ipairs({ "gra", "gri", "grn", "grr", "grt", "grx", "]b", "[b", "]B", "[B" }) do
  pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, "x", "gra")

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "J", "mzJ`z", { desc = "Join lines" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })
map("i", "<C-c>", "<Esc>", { desc = "Escape insert mode" })

map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split window below" })
map("n", "<leader>wv", "<C-w>v", { desc = "Split window right" })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Close other windows" })

map("n", "<leader><tab><tab>", "<cmd>tab split<cr>", { desc = "Open buffer in new tab" })
map("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New empty tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close other tabs" })
map("n", "]t", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "[t", "<cmd>tabprevious<cr>", { desc = "Previous tab" })

map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer (tab bar)" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer (tab bar)" })
map("n", "Q", function()
  require("mini.bufremove").delete(0, false)
end, { desc = "Close buffer (keep window)" })
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted and not vim.bo[buf].modified then
      require("mini.bufremove").delete(buf, false)
    end
  end
end, { desc = "Close other buffers (unsaved kept)" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole" })

map("n", "[q", "<cmd>cprev<cr>zz", { desc = "Previous quickfix item" })
map("n", "]q", "<cmd>cnext<cr>zz", { desc = "Next quickfix item" })
map("n", "[l", "<cmd>lprev<cr>zz", { desc = "Previous location item" })
map("n", "]l", "<cmd>lnext<cr>zz", { desc = "Next location item" })

map("n", "<leader>cd", function()
  vim.diagnostic.open_float()
end, { desc = "Line Diagnostics" })
map("n", "<leader>ud", function()
  local vt = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not vt and { prefix = "●", spacing = 2 } or false })
  vim.notify("Diagnostics virtual_text " .. (vt and "OFF" or "ON"))
end, { desc = "Toggle Diagnostics Virtual Text" })
map("n", "<leader>uh", function()
  local enabled = not vim.lsp.inlay_hint.is_enabled()
  vim.lsp.inlay_hint.enable(enabled)
  vim.notify("Inlay hints " .. (enabled and "ON" or "OFF"))
end, { desc = "Toggle inlay hints" })
map("n", "<leader>tr", function()
  require("custom.runner").run_file()
end, { desc = "Run current file" })
map("n", "<leader>tt", function()
  require("custom.runner").test_file()
end, { desc = "Run tests for current file" })
map("n", "<leader>tl", function()
  require("custom.runner").rerun()
end, { desc = "Rerun last run/test" })
map({ "n", "i", "x", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Netrw Explorer" })
map("n", "<leader>E", function()
  vim.cmd.Explore(vim.fn.getcwd(-1, -1))
end, { desc = "Netrw Explorer (cwd)" })
map("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word" })
map("n", "<leader>cx", function()
  if vim.bo.buftype ~= "" or vim.fn.filereadable(vim.fn.expand("%")) ~= 1 then
    vim.notify("chmod +x: no file in current buffer", vim.log.levels.WARN)
    return
  end
  vim.cmd("!chmod +x %")
end, { silent = true, desc = "Make file executable" })
map("n", "<leader>cs", function()
  local ft = vim.bo.filetype
  if ft ~= "lua" and ft ~= "vim" then
    vim.notify("Source: only lua/vim buffers (current: " .. ft .. ")", vim.log.levels.WARN)
    return
  end
  vim.cmd("source %")
end, { desc = "Source current file" })
