-- Project autocmds: Rails, C++, diagnostics, and Primeagen's save behavior.

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

-- LspAttach keymaps (simple g-family)
vim.api.nvim_create_autocmd("LspAttach", {
  group = PrimeagenGroup,
  callback = function(e)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = e.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Goto definition")
    map("gD", vim.lsp.buf.declaration, "Goto declaration")
    map("gi", vim.lsp.buf.implementation, "Goto implementation")
    map("gy", vim.lsp.buf.type_definition, "Goto type definition")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
    map("<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbol")
    map("<leader>ls", function() vim.lsp.buf.signature_help() end, "Signature help")
    -- diagnostics: [d / ]d follow vim convention (prev / next)
    map("[d", function() vim.diagnostic.goto_prev() end, "Prev diagnostic")
    map("]d", function() vim.diagnostic.goto_next() end, "Next diagnostic")
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  group = PrimeagenGroup,
  callback = function(e)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, { buffer = e.buf, desc = "Signature help" })
  end,
})
