local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("ConfigLsp", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(e)
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = e.buf, desc = desc })
      end
      map("gd", vim.lsp.buf.definition, "Goto definition")
      map("gD", vim.lsp.buf.declaration, "Goto declaration")
      map("gI", vim.lsp.buf.implementation, "Goto implementation")
      map("gy", vim.lsp.buf.type_definition, "Goto type definition")
      map("gr", vim.lsp.buf.references, "References")
      map("K", vim.lsp.buf.hover, "Hover")
      map("<leader>ca", vim.lsp.buf.code_action, "Code action")
      map("gK", function()
        vim.lsp.buf.signature_help()
      end, "Signature help")
      local client = vim.lsp.get_client_by_id(e.data.client_id)
      if client and client.name == "clangd" then
        map("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "C++ Switch Header/Source")
      end
      map("[d", function()
        vim.diagnostic.jump({ count = -1 })
      end, "Prev diagnostic")
      map("]d", function()
        vim.diagnostic.jump({ count = 1 })
      end, "Next diagnostic")
    end,
  })
end

return M
