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

local function scan(source)
  local parser = vim.treesitter.get_string_parser(source, "ruby")
  local defs, requires = {}, {}
  local last_def
  for id, node in query:iter_captures(parser:parse()[1]:root(), source) do
    local capture, text = query.captures[id], vim.treesitter.get_node_text(node, source)
    if capture == "def" then
      last_def = { name = text, params = "", top = node:parent():parent():type() == "program" }
      defs[#defs + 1] = last_def
    elseif capture == "params" and last_def then
      last_def.params = text
    elseif capture == "kind" then
      requires[#requires + 1] = { kind = text }
    elseif capture == "path" then
      requires[#requires].path = text
    end
  end
  return { defs = defs, requires = requires }
end

local function scan_file(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local hit = cache[path]
  if hit and hit.mtime == stat.mtime.sec and hit.size == stat.size then
    return hit.result
  end
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local result = scan(fd:read("*a"))
  fd:close()
  cache[path] = { mtime = stat.mtime.sec, size = stat.size, result = result }
  return result
end

local buffer_cache = {}

local function scan_buffer(buf)
  local tick = vim.b[buf].changedtick
  local hit = buffer_cache[buf]
  if hit and hit.tick == tick then
    return hit.result
  end
  local ok, result = pcall(scan, table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
  result = ok and result or nil
  buffer_cache[buf] = { tick = tick, result = result }
  return result
end

local function buffer_def_names()
  local buf = vim.api.nvim_get_current_buf()
  local result = ok_query and vim.bo[buf].filetype == "ruby" and scan_buffer(buf)
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
  local before = ctx.line:sub(1, ctx.bounds.start_col - 1)
  if before:match("[%.:]$") then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local dir = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
  local root = vim.fs.root(buf, { ".git", "Gemfile" }) or dir

  local items, seen_names, visited = {}, {}, { [vim.fs.normalize(name)] = true }
  local function collect(result, file_dir, origin)
    for _, def in ipairs(result.defs) do
      if (def.top or not origin) and not seen_names[def.name] then
        seen_names[def.name] = true
        items[#items + 1] = {
          label = def.name,
          kind = def.top and vim.lsp.protocol.CompletionItemKind.Function or vim.lsp.protocol.CompletionItemKind.Method,
          detail = "def " .. def.name .. def.params,
          labelDetails = origin and { description = origin } or nil,
          insertText = def.name,
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
        }
      end
    end
    for _, req in ipairs(result.requires) do
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
  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

return M
