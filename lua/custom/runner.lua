local M = {}

local last

local run_by_filetype = {
  ruby = "ruby",
  python = "python3",
  lua = "nvim -l",
  sh = "bash",
  bash = "bash",
  zsh = "zsh",
  javascript = "node",
  typescript = "npx tsx",
}

local function send(cmd, dir)
  last = { cmd = cmd, dir = dir }
  require("custom.terminal").run(("cd %s && %s"):format(vim.fn.shellescape(dir), cmd))
end

local function root_of(path)
  return vim.fs.root(path, { "Gemfile", ".git" }) or vim.fs.dirname(path)
end

local function ruby_test_for(path, root)
  local name = vim.fs.basename(path)
  if name:match("_test%.rb$") or name:match("_spec%.rb$") then
    return path
  end
  local dir, stem = vim.fs.dirname(path), name:gsub("%.rb$", "")
  local rel = path:sub(#root + 2):gsub("^app/", ""):gsub("%.rb$", "")
  for _, candidate in ipairs({
    vim.fs.joinpath(dir, stem .. "_test.rb"),
    vim.fs.joinpath(dir, stem .. "_spec.rb"),
    vim.fs.joinpath(root, "test", rel .. "_test.rb"),
    vim.fs.joinpath(root, "spec", rel .. "_spec.rb"),
    vim.fs.joinpath(root, "test", (rel:gsub("^lib/", "")) .. "_test.rb"),
    vim.fs.joinpath(root, "spec", (rel:gsub("^lib/", "")) .. "_spec.rb"),
  }) do
    if vim.uv.fs_stat(candidate) then
      return candidate
    end
  end
end

local function ruby_test_command(test, root)
  local file = vim.fn.shellescape(test)
  local bundled = vim.uv.fs_stat(vim.fs.joinpath(root, "Gemfile.lock")) and "bundle exec " or ""
  if test:match("_spec%.rb$") then
    return bundled .. "rspec " .. file
  end
  if vim.uv.fs_stat(vim.fs.joinpath(root, "bin/rails")) then
    return "bin/rails test " .. file
  end
  return "ruby -Itest " .. file
end

local function current_file()
  vim.cmd("silent! update")
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.bo.buftype ~= "" then
    vim.notify("Run: this buffer is not a file", vim.log.levels.WARN)
    return nil
  end
  return path
end

function M.run_file()
  local path = current_file()
  if not path then
    return
  end
  local runner = run_by_filetype[vim.bo.filetype]
  if not runner then
    vim.notify("Run: no runner for filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
    return
  end
  send(runner .. " " .. vim.fn.shellescape(path), vim.fs.dirname(path))
end

function M.test_file()
  local path = current_file()
  if not path then
    return
  end
  if vim.bo.filetype ~= "ruby" then
    vim.notify("Test: only Ruby test files are wired up", vim.log.levels.WARN)
    return
  end
  local root = root_of(path)
  local test = ruby_test_for(path, root)
  if not test then
    vim.notify("Test: no _test.rb or _spec.rb found for " .. vim.fs.basename(path), vim.log.levels.WARN)
    return
  end
  send(ruby_test_command(test, root), root)
end

function M.rerun()
  if not last then
    vim.notify("Run: nothing has run yet", vim.log.levels.WARN)
    return
  end
  vim.cmd("silent! wall")
  send(last.cmd, last.dir)
end

return M
