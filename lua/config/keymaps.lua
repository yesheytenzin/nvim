-- Keymaps: Rails API + C++ optimized (VeryLazy)
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Diagnostics
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "<leader>ud", function()
  local vt = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not vt and { prefix = "●", spacing = 2 } or false })
  vim.notify("Diagnostics virtual_text " .. (vt and "OFF" or "ON"))
end, { desc = "Toggle Diagnostics Virtual Text" })

-- C++ (clangd) - header/source switch, already provided by clangd extra but add convenience
vim.keymap.set("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", { desc = "C++ Switch Header/Source" })

-- Quick save/quit (classic, no snacks)
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })


-- ThePrimagen: keep cursor centered when paging
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
-- Optional: centered search jumps + line joins (same disorientation fix)
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search (centered)" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- Primeagen: move lines in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Primeagen: greatest remaps — paste/yank/delete without clobbering registers
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yank" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to blackhole" })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "C-c = Esc" })
vim.keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- Primeagen: quickfix / loclist navigation (centered)
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Quickfix next" })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Quickfix prev" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Loclist next" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Loclist prev" })

-- Primeagen: substitute word under cursor + utils
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor" })
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "chmod +x" })
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end, { desc = "Source file" })

-- File explorer: netrw (stock) — group <leader>f = file, <leader>h = harpoon
vim.keymap.set("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Netrw Explorer (current dir)" })
vim.keymap.set("n", "<leader>E", "<cmd>Lexplore<cr>", { desc = "Netrw Left Explorer (stock)" })
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Netrw Explorer (Primeagen)" })

-- Primeagen telescope word-grep (requires telescope)
vim.keymap.set("n", "<leader>pws", function()
  local word = vim.fn.expand("<cword>")
  require("telescope.builtin").grep_string({ search = word })
end, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>pWs", function()
  local word = vim.fn.expand("<cWORD>")
  require("telescope.builtin").grep_string({ search = word })
end, { desc = "Grep WORD under cursor" })
vim.keymap.set("n", "<leader>ps", function()
  require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep prompt" })
