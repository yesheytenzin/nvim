-- Project-specific keymaps. Primeagen's core remaps live in yesheytenzin/remap.lua.

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
vim.keymap.set("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit" })


-- File explorer: netrw (stock) — group <leader>f = file, <leader>h = harpoon
vim.keymap.set("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Netrw Explorer (current dir)" })

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
