-- All global keymaps in one module, grouped by concern. An earlier
-- remap.lua/keymaps.lua split (Primeagen core vs project) shared one
-- interface with no seam, so they are merged here. LSP-buffer maps live
-- with the LSP spec in lazy/coding.lua, not here.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set

-- ── Core movement & editing (Primeagen) ──────────────────────────────────
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "J", "mzJ`z", { desc = "Join lines" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "n", "nzzzv", { desc = "Next search result" })
map("n", "N", "Nzzzv", { desc = "Previous search result" })
map("i", "<C-c>", "<Esc>", { desc = "Escape insert mode" })
map("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- ── Windows ──────────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- ── Clipboard (black-hole by default, leader to reach system) ────────────
map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole" })

-- ── Quickfix / location ──────────────────────────────────────────────────
map("n", "<leader>qj", "<cmd>cprev<CR>zz", { desc = "Previous quickfix item" })
map("n", "<leader>qk", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location item" })
map("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Previous location item" })

-- ── Project ──────────────────────────────────────────────────────────────
-- Wrapped in a function so vim.diagnostic isn't required at startup; indexing
-- vim.diagnostic.open_float eagerly pulls the whole module in (~1ms).
map("n", "gl", function() vim.diagnostic.open_float() end, { desc = "Line Diagnostics" })
map("n", "<leader>ud", function()
  local vt = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not vt and { prefix = "●", spacing = 2 } or false })
  vim.notify("Diagnostics virtual_text " .. (vt and "OFF" or "ON"))
end, { desc = "Toggle Diagnostics Virtual Text" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Netrw Explorer (current dir)" })
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

-- NOTE: <leader>pf/pg/pb/ph/po/pt/ps/pws/pWs all live in
-- lazy/navigation.lua as lazy.nvim `keys` so Telescope is loaded on demand.
-- Do NOT re-add them here: eager mappings break on fresh `nvim .` startup.
-- NOTE: no global <leader>ch here: :ClangdSwitchSourceHeader only exists with
-- clangd attached — a global map errors in ruby/lua/etc buffers. It is set
-- buffer-local on LspAttach when the client is clangd (see lazy/coding.lua).
