local M = {}

function M.command()
  if vim.fn.executable("mise") == 1 and vim.fn.executable("sh") == 1 then
    return { "sh", "-c", "mise exec -- ruby-lsp || exec ruby-lsp" }
  end
  return { "ruby-lsp" }
end

function M.sequence_completion(client)
  local request, cancel = client.request, client.cancel_request
  local followups = {}

  client.request = function(self, method, params, handler, bufnr)
    if method ~= "textDocument/completion" then
      return request(self, method, params, handler, bufnr)
    end
    local barrier = { textDocument = params.textDocument, position = { line = 0, character = 0 } }
    local barrier_id
    local ok, id = request(self, "textDocument/documentHighlight", barrier, function()
      if followups[barrier_id] == false then
        followups[barrier_id] = nil
        return
      end
      local _, real_id = request(self, method, params, handler, bufnr)
      followups[barrier_id] = real_id
    end, bufnr)
    barrier_id = id
    return ok, id
  end

  client.cancel_request = function(self, id)
    local real_id = followups[id]
    if real_id then
      followups[id] = nil
      return cancel(self, real_id)
    end
    if real_id == nil then
      followups[id] = false
    end
    return cancel(self, id)
  end
end

function M.setup_refresh()
  local group = vim.api.nvim_create_augroup("ConfigRubyLspIndex", { clear = true })
  local timer = vim.uv.new_timer()
  local refreshed = {}

  local function refresh(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local tick = vim.b[bufnr].changedtick
    if refreshed[bufnr] == tick then
      return
    end
    refreshed[bufnr] = tick

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if client.name == "ruby_lsp" then
        local uri = vim.uri_from_bufnr(bufnr)
        local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
        client:notify("textDocument/didOpen", {
          textDocument = {
            uri = uri,
            languageId = vim.bo[bufnr].filetype,
            version = (vim.lsp.util.buf_versions or {})[bufnr] or 0,
            text = text,
          },
        })
        client:request("textDocument/documentSymbol", { textDocument = { uri = uri } }, function() end, bufnr)
        return
      end
    end
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = { "*.rb", "*.rake" },
    callback = function(e)
      timer:stop()
      timer:start(500, 0, function()
        vim.schedule(function()
          refresh(e.buf)
        end)
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
    group = group,
    pattern = { "*.rb", "*.rake" },
    callback = function(e)
      refresh(e.buf)
    end,
  })
end

return M
