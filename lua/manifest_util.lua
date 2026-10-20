-- Shared "wanted vs installed" checks for the toolchain manifests.
-- Pure helpers (no autocmds/commands on require) so startup code
-- (lua/plugins/treesitter.lua), headless prefetch (scripts/bootstrap.lua) and the
-- live watcher (lua/toolchain.lua) can all use them without side effects.
local M = {}

--- Parser names in `wanted` with no compiled .so / queries entry.
--- @param wanted string[]
--- @return string[] missing
function M.ts_missing(wanted)
  local installed = require("nvim-treesitter.config").get_installed()
  return vim.tbl_filter(function(p)
    return not vim.list_contains(installed, p)
  end, wanted)
end

--- Mason package names in `pkgs` that are not installed.
--- @param mr table mason-registry module
--- @param pkgs string[]
--- @return string[] missing
function M.mason_missing(mr, pkgs)
  return vim.tbl_filter(function(name)
    local ok, pkg = pcall(mr.get_package, name)
    return not (ok and pkg:is_installed())
  end, pkgs)
end

--- "name@version" specifier for Mason commands, or the plain name when the
--- entry carries no pin.
--- @param name string
--- @param version string?
--- @return string
function M.spec(name, version)
  if version and version ~= "" then
    return name .. "@" .. version
  end
  return name
end

--- Installed Mason registry version of `name`, or nil when absent.
--- @param mr table mason-registry module
--- @param name string
--- @return string?
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

--- Manifest entries (with .mason or .name plus optional .version) that need
--- installing: absent packages, plus installed ones whose version drifted
--- from the pin. Returns "name@version" specifiers.
--- @param mr table mason-registry module
--- @param entries table[]
--- @return string[] specs
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

--- Ruby versions mise has installed.
--- @return { version: string, install_path: string }[]
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

--- Highest version of the Ruby gem `name` installed for `ruby_version`, or
--- nil when that Ruby does not have the gem. mise's `x` runs the command
--- with that Ruby, so this answers for the Ruby the LSP would actually
--- load, not for whatever `gem` happens to be first on PATH.
--- @param ruby_version string
--- @param name string
--- @return string?
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

--- Rubies (from `mise_rubies`) that do not have the gem `name` at the
--- pinned `version`. A gem with native extensions needs one copy per Ruby:
--- the compiled .so is ABI-specific and the wrong one is rejected.
--- @param name string
--- @param version string
--- @return string[] ruby_versions
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
