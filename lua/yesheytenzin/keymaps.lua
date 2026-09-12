-- Project-specific keymaps. Primeagen's core remaps live in yesheytenzin/remap.lua.

-- Diagnostics
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "<leader>ud", function()
  local vt = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not vt and { prefix = "●", spacing = 2 } or false })
  vim.notify("Diagnostics virtual_text " .. (vt and "OFF" or "ON"))
end, { desc = "Toggle Diagnostics Virtual Text" })

-- NOTE: no global <leader>ch here: :ClangdSwitchSourceHeader only exists with
-- clangd attached — a global map errors in ruby/lua/etc buffers. It is set
-- buffer-local on LspAttach when the client is clangd (see autocmds.lua).

-- Quick save/quit (classic, no snacks)
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>qq", "<cmd>q<cr>", { desc = "Quit" })


-- File explorer: netrw (stock) — group <leader>f = file, <leader>h = harpoon
vim.keymap.set("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Netrw Explorer (current dir)" })

-- NOTE: <leader>pf/pg/pb/ph/po/pt/ps/pws/pWs all live in
-- lazy/navigation.lua as lazy.nvim `keys` so Telescope is loaded on demand.
-- Do NOT re-add them here: eager mappings break on fresh `nvim .` startup.
