local M = {}

local uv = vim.uv or vim.loop
local theme_path = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
local pack_util = require("custom.pack")

local installed = {}
local active_plugin

local function module_name(base)
  if base == "nvim" then
    return "catppuccin"
  end
  return (base:gsub("%.nvim$", ""):gsub("%-nvim$", ""))
end

local function plugin_dir(name)
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", name)
end

local function unload_modules(name)
  local root = plugin_dir(name) .. "/lua"
  if vim.fn.isdirectory(root) ~= 1 then
    return
  end
  for _, file in ipairs(vim.fn.glob(root .. "/**/*.lua", false, true)) do
    local rel = file:sub(#root + 2):gsub("%.lua$", ""):gsub("/", ".")
    package.loaded[rel] = nil
    package.preload[rel] = nil
  end
end

local function read_spec()
  local chunk, load_err = loadfile(theme_path)
  if not chunk then
    if vim.fn.filereadable(theme_path) == 1 then
      vim.notify("theme: cannot load Omarchy theme: " .. tostring(load_err), vim.log.levels.ERROR)
    end
    return nil
  end
  local ok, spec = pcall(chunk)
  if not ok then
    vim.notify("theme: invalid Omarchy theme: " .. tostring(spec), vim.log.levels.ERROR)
    return nil
  end
  if type(spec) ~= "table" then
    vim.notify("theme: Omarchy theme must return a table", vim.log.levels.ERROR)
    return nil
  end
  return spec
end

local function parse(spec)
  local plugin, colorscheme
  for _, s in ipairs(spec) do
    if s[1] == "LazyVim/LazyVim" then
      colorscheme = (s.opts and s.opts.colorscheme) or colorscheme
    elseif type(s[1]) == "string" then
      local name = s.name or pack_util.basename(s[1])
      plugin = {
        src = s[1],
        name = name,
        version = s.version or s.branch,
        opts = s.opts,
        module = module_name(name),
      }
    end
  end
  if not colorscheme and plugin then
    local inferred = {
      kanagawa = "kanagawa",
      tokyonight = "tokyonight-night",
      catppuccin = "catppuccin",
      gruvbox = "gruvbox",
      ["rose-pine"] = "rose-pine-dawn",
    }
    local base = plugin.name:lower()
    for key, scheme in pairs(inferred) do
      if base:find(key, 1, true) then
        colorscheme = scheme
        break
      end
    end
  end
  return plugin, colorscheme
end

local function ensure(plugin)
  if not plugin then
    return true
  end
  local src = pack_util.full_src(plugin.src)
  local add_ok, add_err = pcall(
    vim.pack.add,
    { { src = src, name = plugin.name, version = plugin.version } },
    { load = false, confirm = false }
  )
  if not add_ok then
    vim.notify(("theme: cannot install %s: %s"):format(plugin.name, add_err), vim.log.levels.ERROR)
    return false
  end
  if installed[plugin.name] then
    return true
  end
  local load_ok, load_err = pcall(vim.cmd.packadd, plugin.name)
  if not load_ok then
    vim.notify(("theme: cannot load %s: %s"):format(plugin.name, load_err), vim.log.levels.ERROR)
    return false
  end
  if plugin.opts then
    local ok, mod = pcall(require, plugin.module)
    if not ok or type(mod) ~= "table" or type(mod.setup) ~= "function" then
      vim.notify(("theme: %s has no setup function"):format(plugin.module), vim.log.levels.ERROR)
      return false
    end
    local setup_ok, setup_err = pcall(mod.setup, plugin.opts)
    if not setup_ok then
      vim.notify(("theme: setup failed for %s: %s"):format(plugin.name, setup_err), vim.log.levels.ERROR)
      return false
    end
  end
  installed[plugin.name] = true
  return true
end

function M.load()
  local spec = read_spec()
  if not spec then
    return
  end
  local plugin, colorscheme = parse(spec)
  if not colorscheme then
    return
  end
  if not ensure(plugin) then
    return
  end
  active_plugin = plugin and plugin.name or active_plugin
  if vim.g.applied_colorscheme == colorscheme then
    return
  end
  if pcall(vim.cmd.colorscheme, colorscheme) then
    vim.g.applied_colorscheme = colorscheme
  end
end

function M.reload()
  vim.schedule(function()
    local spec = read_spec()
    if not spec then
      return
    end
    local plugin, colorscheme = parse(spec)
    if not colorscheme then
      return
    end

    local previous = active_plugin
    if not ensure(plugin) then
      return
    end
    active_plugin = plugin and plugin.name or active_plugin

    if vim.g.applied_colorscheme == colorscheme then
      return
    end

    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then
      vim.cmd("syntax reset")
    end

    if previous and previous ~= active_plugin then
      unload_modules(previous)
    end

    if pcall(vim.cmd.colorscheme, colorscheme) then
      vim.g.applied_colorscheme = colorscheme
    end
    vim.defer_fn(function()
      if pcall(vim.cmd.colorscheme, colorscheme) then
        vim.g.applied_colorscheme = colorscheme
      end
      vim.cmd("redraw!")
    end, 10)
  end)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    if vim.g.applied_colorscheme == nil then
      M.load()
    end
  end,
})

if vim.v.servername == "" or vim.v.servername == nil then
  pcall(vim.fn.mkdir, vim.fn.stdpath("run"), "p")
  pcall(vim.fn.serverstart, vim.fn.stdpath("run") .. "/nvim." .. vim.fn.getpid() .. ".0")
end

do
  if uv and theme_path then
    local poll = uv.new_fs_poll()
    if poll then
      poll:start(theme_path, 500, function(err, prev, curr)
        if err then
          return
        end
        if prev and curr and curr.mtime and prev.mtime and curr.mtime.sec ~= prev.mtime.sec then
          M.reload()
        end
      end)
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          pcall(function()
            poll:stop()
            poll:close()
          end)
        end,
      })
    end
  end
end

return M
