-- Native plugin management on top of Neovim's built-in vim.pack + :packadd.
--
-- vim.pack owns install / update / lock; this module supplies the pieces it
-- deliberately omits: trigger-driven loading (keys / cmd / ft / event /
-- colorscheme) and a per-plugin config() lifecycle. No third-party manager.
--
-- Loading model: every plugin is added with load = false (installed, on the
-- runtimepath, plugin/ files unsourced). The first trigger fires
-- :packadd <name> and runs the spec's config(). Dependencies load first.
-- `eager = true` skips the trigger and loads at startup, in declaration order.

local M = {}

local specs = {} --- @type table<string, table>
local loaded = {} --- @type table<string, boolean|nil>
local cmd_index = {} --- @type table<string, string>

local group = vim.api.nvim_create_augroup("ConfigPack", { clear = true })

local function basename(src)
  return (src:gsub("%.git$", ""):match("[^/]+$"))
end

-- vim.pack wants a git-clone-able URI; specs use the short "owner/repo" form.
local function full_src(src)
  if src:find("://", 1, true) or src:match("^[%w]+:") then
    return src
  end
  return "https://github.com/" .. src
end

-- Shared with lua/custom/omarchy_theme.lua (omarchy theme bridge), which resolves the same
-- short specs outside the pack lifecycle.
M.basename = basename
M.full_src = full_src

local function plugin_dir(name)
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", name)
end

-- :packadd sources plugin/ and ftdetect/ but not after/plugin/. Mirror what
-- vim.pack does internally and source those explicitly so after/ hooks run.
local function source_after_plugin(name)
  for _, file in ipairs(vim.fn.glob(plugin_dir(name) .. "/after/plugin/**/*.{vim,lua}", false, true)) do
    pcall(vim.cmd.source, file)
  end
end

--- Load a plugin (and its deps) if not already loaded. Idempotent.
--- @param name string
--- @return boolean
function M.load(name)
  if loaded[name] then
    return true
  end
  local spec = specs[name]
  if not spec or spec.enabled == false then
    return false
  end
  loaded[name] = true

  for _, dep in ipairs(spec.deps or {}) do
    M.load(dep)
  end

  local ok, err = pcall(vim.cmd.packadd, name)
  if not ok then
    loaded[name] = nil
    vim.notify(("pack: cannot load %s: %s"):format(name, err), vim.log.levels.ERROR)
    return false
  end

  source_after_plugin(name)

  if type(spec.config) == "function" then
    local ok2, err2 = pcall(spec.config)
    if not ok2 then
      vim.notify(("pack: config error in %s: %s"):format(name, err2), vim.log.levels.ERROR)
    end
  end
  return true
end

local function run_rhs(rhs)
  if type(rhs) == "function" then
    return rhs()
  end
  if type(rhs) == "string" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(rhs, true, false, true), "m", false)
  end
end

local function install_keys(name, keys)
  for _, k in ipairs(keys) do
    local lhs, rhs = k[1], k[2]
    local opts = { desc = k.desc, silent = true, expr = k.expr }
    local handler
    if k.expr then
      handler = function()
        if not M.load(name) then
          return ""
        end
        return run_rhs(rhs) or ""
      end
    else
      handler = function()
        if not M.load(name) then
          return
        end
        run_rhs(rhs)
      end
    end
    vim.keymap.set(k.mode or "n", lhs, handler, opts)
  end
end

-- Commands are not pre-defined (that would shadow the plugin's real ones).
-- CmdUndefined fires for unknown commands; we load the owning plugin and
-- Neovim re-runs the command with its original arguments.
local function install_commands(name, cmds)
  if type(cmds) == "string" then
    cmds = { cmds }
  end
  for _, cmd in ipairs(cmds) do
    cmd_index[cmd] = name
  end
end

local function install_ft(name, fts)
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = fts,
    callback = function() M.load(name) end,
  })
end

local function install_events(name, events)
  if type(events) == "string" then
    events = { events }
  end
  for _, ev in ipairs(events) do
    local pattern
    if ev == "VeryLazy" then
      ev, pattern = "User", "VeryLazy"
    end
    vim.api.nvim_create_autocmd(ev, {
      group = group,
      pattern = pattern,
      callback = function() M.load(name) end,
    })
  end
end

--- @param list table[] aggregated plugin specs
function M.setup(list)
  -- Register the build hook before the first add() so install-time builds run.
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local spec = specs[ev.data.spec.name]
      if spec and spec.build and (ev.data.kind == "install" or ev.data.kind == "update") then
        local ok, err = pcall(spec.build, ev.data.path)
        if not ok then
          vim.notify(("pack: build failed for %s: %s"):format(ev.data.spec.name, err), vim.log.levels.ERROR)
        end
      end
    end,
  })

  local adds = {}
  for _, s in ipairs(list) do
    local name = s.name or basename(s[1])
    local enabled = s.enabled
    if type(enabled) == "function" then
      enabled = enabled()
    end
    if s.cond ~= nil then
      local cond = type(s.cond) == "function" and s.cond() or s.cond
      if not cond then
        enabled = false
      end
    end
    specs[name] = {
      src = full_src(s[1]),
      name = name,
      version = s.version or s.branch,
      deps = s.deps,
      config = s.config,
      build = s.build,
      enabled = enabled,
      eager = s.eager,
    }
    if enabled ~= false then
      adds[#adds + 1] = { src = full_src(s[1]), name = name, version = s.version or s.branch }
    end
  end

  -- vim.pack installs into stdpath('data')/site; ensure it is on 'packpath'
  -- (lazy.nvim used to reset packpath to the runtime only).
  local site = vim.fs.joinpath(vim.fn.stdpath("data"), "site")
  if not vim.o.packpath:find(site, 1, true) then
    vim.opt.packpath:prepend(site)
  end

  -- A single unreachable repo must not abort startup; vim.pack reports the
  -- per-plugin errors and we surface them, then continue with what's on disk.
  local before = {}
  for _, p in ipairs(vim.api.nvim_list_runtime_paths()) do
    before[vim.fs.normalize(p)] = true
  end
  local ok, err = pcall(vim.pack.add, adds, { load = false, confirm = false })
  if not ok then
    vim.notify(("pack: install problems:\n%s"):format(err), vim.log.levels.ERROR)
  end
  -- vim.pack.add appends each plugin to 'runtimepath' (via :packadd!). Neovim
  -- would then source every plugin/ file during the startup plugin phase,
  -- which would defeat lazy loading. Drop the newly added entries; M.load
  -- re-adds each one on demand with a real :packadd (which sources it).
  local kept = {}
  for _, p in ipairs(vim.api.nvim_list_runtime_paths()) do
    if before[vim.fs.normalize(p)] then
      kept[#kept + 1] = p
    end
  end
  vim.opt.runtimepath = table.concat(kept, ",")

  vim.api.nvim_create_autocmd("CmdUndefined", {
    group = group,
    callback = function()
      local name = cmd_index[vim.fn.expand("<amatch>")]
      if name then
        M.load(name)
      end
    end,
  })

  for _, s in ipairs(list) do
    local name = s.name or basename(s[1])
    if specs[name].enabled ~= false then
      if s.keys then install_keys(name, s.keys) end
      if s.cmd then install_commands(name, s.cmd) end
      if s.ft then install_ft(name, s.ft) end
      if s.event then install_events(name, s.event) end
    end
  end

  for _, s in ipairs(list) do
    local name = s.name or basename(s[1])
    if s.eager and specs[name].enabled ~= false then
      M.load(name)
    end
  end
end

--- Names of all registered specs (for tooling / verification).
--- @return string[]
function M.list()
  local names = {}
  for name in pairs(specs) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

-- Emulate lazy.nvim's VeryLazy: one User event after startup. Modules
-- (remote_clipboard, theme) hook it, and specs may use event = { "VeryLazy" }.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
    end)
  end,
})

return M
