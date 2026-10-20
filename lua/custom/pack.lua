local M = {}

local specs = {}
local states = {}
local cmd_index = {}

local group = vim.api.nvim_create_augroup("ConfigPack", { clear = true })

local function basename(src)
  return (src:gsub("%.git$", ""):match("[^/]+$"))
end

local function full_src(src)
  if src:find("://", 1, true) or src:match("^[%w]+:") then
    return src
  end
  return "https://github.com/" .. src
end

M.basename = basename
M.full_src = full_src

local function plugin_dir(name)
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", name)
end

local function source_after_plugin(name)
  for _, file in ipairs(vim.fn.glob(plugin_dir(name) .. "/after/plugin/**/*.{vim,lua}", false, true)) do
    local ok, err = pcall(vim.cmd.source, file)
    if not ok then
      return false, err
    end
  end
  return true
end

local function load_plan(name)
  local plan = {}
  local visiting = {}
  local planned = {}

  local function visit(current)
    local spec = specs[current]
    if not spec or spec.enabled == false or states[current] == "failed" then
      return false, ("dependency unavailable: %s"):format(current)
    end
    if states[current] == "loading" then
      return false, ("dependency is already loading: %s"):format(current)
    end
    if states[current] == "loaded" or planned[current] then
      return true
    end
    if visiting[current] then
      return false, ("dependency cycle at %s"):format(current)
    end

    visiting[current] = true
    for _, dep in ipairs(spec.deps or {}) do
      local ok, err = visit(dep)
      if not ok then
        return false, err
      end
    end
    visiting[current] = nil
    planned[current] = true
    plan[#plan + 1] = current
    return true
  end

  local ok, err = visit(name)
  return ok and plan or nil, err
end

local function fail(name, stage, err)
  states[name] = "failed"
  vim.notify(("pack: %s failed for %s: %s"):format(stage, name, err), vim.log.levels.ERROR)
  return false
end

function M.load(name)
  if states[name] == "loaded" then
    return true
  end
  if states[name] == "failed" then
    return false
  end
  local requested = specs[name]
  if not requested or requested.enabled == false then
    return false
  end
  local plan, plan_err = load_plan(name)
  if not plan then
    if specs[name] then
      states[name] = "failed"
    end
    vim.notify(("pack: cannot load %s: %s"):format(name, plan_err), vim.log.levels.ERROR)
    return false
  end

  for _, current in ipairs(plan) do
    if states[current] ~= "loaded" then
      if states[current] == "failed" or states[current] == "loading" then
        return false
      end
      local spec = specs[current]
      states[current] = "loading"

      local ok, err = pcall(vim.cmd.packadd, current)
      if not ok then
        return fail(current, "packadd", err)
      end

      local after_ok, after_err = source_after_plugin(current)
      if not after_ok then
        return fail(current, "after/plugin", after_err)
      end

      if type(spec.config) == "function" then
        local config_ok, config_err = pcall(spec.config)
        if not config_ok then
          return fail(current, "config", config_err)
        end
      end

      states[current] = "loaded"
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
    callback = function()
      M.load(name)
    end,
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
      callback = function()
        M.load(name)
      end,
    })
  end
end

function M.setup(list)
  vim.api.nvim_clear_autocmds({ group = group })
  local previous_specs = specs
  local previous_states = states
  specs = {}
  states = {}
  cmd_index = {}

  vim.api.nvim_create_autocmd("PackChanged", {
    group = group,
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
    local previous_state = previous_states[name]
    if
      previous_specs[name]
      and previous_specs[name].src == specs[name].src
      and (previous_state == "loaded" or previous_state == "failed")
    then
      states[name] = previous_state
    else
      states[name] = "registered"
    end
    if enabled ~= false then
      adds[#adds + 1] = { src = full_src(s[1]), name = name, version = s.version or s.branch }
    end
  end

  local site = vim.fs.joinpath(vim.fn.stdpath("data"), "site")
  if not vim.o.packpath:find(site, 1, true) then
    vim.opt.packpath:prepend(site)
  end

  local before = {}
  for _, p in ipairs(vim.api.nvim_list_runtime_paths()) do
    before[vim.fs.normalize(p)] = true
  end
  local ok, err = pcall(vim.pack.add, adds, { load = false, confirm = false })
  if not ok then
    vim.notify(("pack: install problems:\n%s"):format(err), vim.log.levels.ERROR)
  end
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
      if s.keys then
        install_keys(name, s.keys)
      end
      if s.cmd then
        install_commands(name, s.cmd)
      end
      if s.ft then
        install_ft(name, s.ft)
      end
      if s.event then
        install_events(name, s.event)
      end
    end
  end

  for _, s in ipairs(list) do
    local name = s.name or basename(s[1])
    if s.eager and specs[name].enabled ~= false then
      M.load(name)
    end
  end
end

function M.list()
  local names = {}
  for name in pairs(specs) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
    end)
  end,
})

return M
