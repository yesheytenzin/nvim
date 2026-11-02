local M = {}

local ok_query, query = pcall(
  vim.treesitter.query.parse,
  "ruby",
  [[
  (method name: (_) @def parameters: (method_parameters)? @params)
  (singleton_method name: (_) @def parameters: (method_parameters)? @params)
  (program (call
    method: (identifier) @kind (#any-of? @kind "require" "require_relative")
    arguments: (argument_list . (string (string_content) @path))))
]]
)

local cache = {}

local function empty_result()
  return { defs = {}, requires = {} }
end

local function scan(source)
  if not ok_query or not query then
    return empty_result()
  end
  -- String parser needs the ruby parser installed; fail soft so blink
  -- still calls back (buffer source then acts as fallback).
  local ok_parser, parser = pcall(vim.treesitter.get_string_parser, source, "ruby")
  if not ok_parser or not parser then
    return empty_result()
  end
  local ok_parse, trees = pcall(function()
    return parser:parse()
  end)
  if not ok_parse or not trees or not trees[1] then
    return empty_result()
  end
  local defs, requires = {}, {}
  local last_def
  local ok_iter = pcall(function()
    for id, node in query:iter_captures(trees[1]:root(), source) do
      local capture = query.captures[id]
      local ok_text, text = pcall(vim.treesitter.get_node_text, node, source)
      if ok_text and text then
        if capture == "def" then
          local parent = node:parent()
          local grand = parent and parent:parent()
          last_def = { name = text, params = "", top = grand ~= nil and grand:type() == "program" }
          defs[#defs + 1] = last_def
        elseif capture == "params" and last_def then
          last_def.params = text
        elseif capture == "kind" then
          requires[#requires + 1] = { kind = text }
        elseif capture == "path" and #requires > 0 then
          requires[#requires].path = text
        end
      end
    end
  end)
  if not ok_iter then
    return empty_result()
  end
  return { defs = defs, requires = requires }
end

local function mtime_key(stat)
  -- sec granularity caused stale hits after quick :w/:wq cycles.
  return string.format("%d.%09d:%d", stat.mtime.sec, stat.mtime.nsec or 0, stat.size)
end

local function scan_file(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local key = mtime_key(stat)
  local hit = cache[path]
  if hit and hit.key == key then
    return hit.result
  end
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  -- Never let a broken required file kill the whole completion callback.
  local ok, result = pcall(scan, content or "")
  if not ok or not result then
    return nil
  end
  cache[path] = { key = key, result = result }
  return result
end

local buffer_cache = {}

-- bufnr integers get reused after :wq + reopen; drop stale entries.
pcall(vim.api.nvim_create_autocmd, { "BufWipeout", "BufDelete" }, {
  group = vim.api.nvim_create_augroup("ConfigRubyDefsCache", { clear = true }),
  callback = function(e)
    buffer_cache[e.buf] = nil
  end,
})

local function scan_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  local ok_tick, tick = pcall(vim.api.nvim_buf_get_changedtick, buf)
  if not ok_tick then
    tick = vim.b[buf].changedtick
  end
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local hit = buffer_cache[buf]
  -- Also validate buffer name: guards bufnr-reuse stale hits.
  if hit and hit.tick == tick and hit.name == buf_name then
    return hit.result
  end
  local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, buf, 0, -1, false)
  if not ok_lines then
    return nil
  end
  local ok, result = pcall(scan, table.concat(lines, "\n"))
  result = ok and result or nil
  buffer_cache[buf] = { tick = tick, name = buf_name, result = result }
  return result
end

local function buffer_def_names()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "ruby" then
    return nil
  end
  local result = scan_buffer(buf)
  if not result then
    return nil
  end
  local names = {}
  for _, def in ipairs(result.defs) do
    names[def.name] = true
  end
  return names, vim.fs.basename(vim.api.nvim_buf_get_name(buf))
end

function M.drop_lsp_duplicates(_, items)
  local names, file = buffer_def_names()
  if not names then
    return items
  end
  return vim.tbl_filter(function(item)
    local origin = item.labelDetails and item.labelDetails.description
    return not (names[item.label] and origin == file)
  end, items)
end

function M.drop_buffer_duplicates(_, items)
  -- Only dedup when our ruby_defs source can actually supply the item.
  -- If treesitter scan fails (parser missing / broken syntax right after
  -- typing), scan_buffer is nil and we must keep buffer words as fallback,
  -- otherwise the fresh func disappears from ALL sources.
  local names = buffer_def_names()
  if not names then
    return items
  end
  return vim.tbl_filter(function(item)
    return not names[item.label]
  end, items)
end

local function resolve(req, from_dir, root)
  local rel = req.path:match("%.rb$") and req.path or req.path .. ".rb"
  local candidates = req.kind == "require_relative" and { vim.fs.joinpath(from_dir, rel) }
    or { vim.fs.joinpath(root, "lib", rel), vim.fs.joinpath(root, rel), vim.fs.joinpath(from_dir, rel) }
  for _, path in ipairs(candidates) do
    path = vim.fs.normalize(path)
    if vim.uv.fs_stat(path) then
      return path
    end
  end
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return ok_query and vim.bo.filetype == "ruby"
end

function M:get_completions(ctx, callback)
  local done = function(items)
    local ok_cb = pcall(callback, {
      items = items or {},
      is_incomplete_forward = false,
      is_incomplete_backward = false,
    })
    if not ok_cb then
      pcall(callback, { items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    end
  end
  local ok = pcall(function()
    local before = ctx.line:sub(1, ctx.bounds.start_col - 1)
    if before:match("[%.:]$") then
      done({})
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local dir = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
    local root = vim.fs.root(buf, { ".git", "Gemfile" }) or dir

    local items, seen_names, visited = {}, {}, { [vim.fs.normalize(name)] = true }
    local function collect(result, file_dir, origin)
      if not result then
        return
      end
      for _, def in ipairs(result.defs or {}) do
        if (def.top or not origin) and def.name and not seen_names[def.name] then
          seen_names[def.name] = true
          items[#items + 1] = {
            label = def.name,
            kind = def.top and vim.lsp.protocol.CompletionItemKind.Function or vim.lsp.protocol.CompletionItemKind.Method,
            detail = "def " .. def.name .. (def.params or ""),
            labelDetails = origin and { description = origin } or nil,
            insertText = def.name,
            insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
          }
        end
      end
      for _, req in ipairs(result.requires or {}) do
        local path = req.path and resolve(req, file_dir, root)
        if path and not visited[path] then
          visited[path] = true
          local sub = scan_file(path)
          if sub then
            collect(sub, vim.fs.dirname(path), vim.fs.basename(path))
          end
        end
      end
    end

    local result = scan_buffer(buf)
    if result then
      collect(result, dir, nil)
    end
    done(items)
  end)
  if not ok then
    done({})
  end
end

return M
