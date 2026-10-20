local M = {}

function M.ts_missing(wanted)
  local ok, ts = pcall(require, "nvim-treesitter")
  if not ok then
    return wanted
  end
  local installed = ts.get_installed("parsers")
  return vim.tbl_filter(function(p)
    return not vim.list_contains(installed, p)
  end, wanted)
end

function M.mason_missing(mr, pkgs)
  return vim.tbl_filter(function(name)
    local ok, pkg = pcall(mr.get_package, name)
    return not (ok and pkg:is_installed())
  end, pkgs)
end

function M.spec(name, version)
  if version and version ~= "" then
    return name .. "@" .. version
  end
  return name
end

function M.installed_version(mr, name)
  local ok, pkg = pcall(mr.get_package, name)
  if not ok or not pkg:is_installed() then
    return nil
  end
  local vok, ver = pcall(function()
    return pkg:get_installed_version()
  end)
  return vok and ver or "installed"
end

function M.mason_drift(mr, entries)
  local need = {}
  for _, e in ipairs(entries) do
    local name = e.mason or e.name
    local ver = M.installed_version(mr, name)
    if ver == nil or (e.version and ver ~= e.version) then
      need[#need + 1] = M.spec(name, e.version)
    end
  end
  return need
end

function M.mise_rubies()
  local out = vim.fn.system({ "mise", "ls", "ruby", "--json" })
  local ok, list = pcall(vim.json.decode, out)
  if not ok or type(list) ~= "table" then
    return {}
  end
  return vim.tbl_filter(function(r)
    return r.installed == true and type(r.version) == "string"
  end, list)
end

function M.gem_version(ruby_version, name)
  local out = vim.fn.system({ "mise", "x", "ruby@" .. ruby_version, "--", "gem", "list", "--exact", name })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local best
  for line in out:gmatch("[^\r\n]+") do
    for v in line:gmatch("%(([%d%.]+)") do
      if not best or vim.version.gt(v, best) then
        best = v
      end
    end
  end
  return best
end

function M.gem_drift(name, version)
  local need = {}
  for _, r in ipairs(M.mise_rubies()) do
    if M.gem_version(r.version, name) ~= version then
      need[#need + 1] = r.version
    end
  end
  return need
end

return M
