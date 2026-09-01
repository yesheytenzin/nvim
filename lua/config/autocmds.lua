-- Autocmds: Rails API + C++ (VeryLazy)
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Ruby/Rails API: 2-space indent, no wrap
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "ruby", "eruby", "yaml" },
  callback = function() vim.opt_local.shiftwidth = 2; vim.opt_local.tabstop = 2; vim.opt_local.expandtab = true end,
})

-- C/C++: 2-space (or 4) - clangd will format, keep 2 for consistency with Rails
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function() vim.opt_local.shiftwidth = 2; vim.opt_local.tabstop = 2; vim.opt_local.expandtab = true end,
})

-- Primeagen: trim trailing whitespace on save (prevents rubocop/clang noise)
local PrimeagenGroup = vim.api.nvim_create_augroup("ThePrimeagen", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = PrimeagenGroup,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Primeagen: LspAttach keymaps (gd, K, <leader>v*, [d ]d, C-h)
vim.api.nvim_create_autocmd("LspAttach", {
  group = PrimeagenGroup,
  callback = function(e)
    local opts = { buffer = e.buf }
    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, vim.tbl_extend("force", opts, { desc = "Goto definition" }))
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, vim.tbl_extend("force", opts, { desc = "Hover" }))
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, vim.tbl_extend("force", opts, { desc = "Workspace symbol" }))
    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, vim.tbl_extend("force", opts, { desc = "Diagnostic float" }))
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, vim.tbl_extend("force", opts, { desc = "Code action" }))
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, vim.tbl_extend("force", opts, { desc = "References" }))
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, vim.tbl_extend("force", opts, { desc = "Rename" }))
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, vim.tbl_extend("force", opts, { desc = "Signature help" }))
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, vim.tbl_extend("force", opts, { desc = "Prev diagnostic" }))
  end,
})
