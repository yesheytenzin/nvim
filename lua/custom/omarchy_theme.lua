-- Omarchy theme bridge: reads the omarchy-managed neovim.lua at
-- ~/.local/state/omarchy/current/theme/neovim.lua, installs the referenced
-- theme plugin via vim.pack, and applies its colorscheme. Also handles
-- hot-swapping when omarchy stages a new theme (hook via --remote-send, or the
-- fs watcher below).
--
-- No plugin manager internals here: theme plugins live in vim.pack's directory
-- and are loaded with :packadd.
local M = {}

local uv = vim.uv or vim.loop
local theme_path = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
local pack_util = require("custom.pack")

local installed = {} -- plugin name -> true once packadd'd + setup
local active_plugin -- name of the theme plugin currently applied

-- Lua module name for a colorscheme plugin (repo basename is not always the
-- module: e.g. catppuccin/nvim -> "catppuccin", tokyonight.nvim -> "tokyonight").
local function module_name(base)
  if base == "nvim" then return "catppuccin" end
  return (base:gsub("%.nvim$", ""):gsub("%-nvim$", ""))
end

local function plugin_dir(name)
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", name)
end

local function unload_modules(name)
  local root = plugin_dir(name) .. "/lua"
  if vim.fn.isdirectory(root) ~= 1 then return end
  for _, file in ipairs(vim.fn.glob(root .. "/**/*.lua", false, true)) do
    local rel = file:sub(#root + 2):gsub("%.lua$", ""):gsub("/", ".")
    package.loaded[rel] = nil
    package.preload[rel] = nil
  end
end

-- Load omarchy's currently active neovim.lua directly. The old config kept a
-- symlink at lua/custom/plugins/theme.lua; reading the state file avoids carrying a
-- machine-specific symlink into this repo.
local function read_spec()
  local chunk = loadfile(theme_path)
  if not chunk then return nil end
  local ok, spec = pcall(chunk)
  if not ok or type(spec) ~= "table" then return nil end
  return spec
end

-- Pull the theme plugin descriptor + colorscheme name out of the omarchy spec.
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
    -- Pure-lazy spec without a LazyVim marker: infer from the plugin.
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

-- Ensure the theme plugin is installed and sourced (idempotent per session).
local function ensure(plugin)
  if not plugin then return end
  local src = pack_util.full_src(plugin.src)
  pcall(vim.pack.add, { { src = src, name = plugin.name, version = plugin.version } }, { load = false, confirm = false })
  if installed[plugin.name] then return end
  installed[plugin.name] = true
  pcall(vim.cmd.packadd, plugin.name)
  if plugin.opts then
    local ok, mod = pcall(require, plugin.module)
    if ok and type(mod) == "table" and type(mod.setup) == "function" then
      pcall(mod.setup, plugin.opts)
    end
  end
end

--- Install + apply the current omarchy theme synchronously (called from init).
function M.load()
  local spec = read_spec()
  if not spec then return end
  local plugin, colorscheme = parse(spec)
  if not colorscheme then return end
  ensure(plugin)
  active_plugin = plugin and plugin.name or active_plugin
  if vim.g.applied_colorscheme == colorscheme then return end
  if pcall(vim.cmd.colorscheme, colorscheme) then
    vim.g.applied_colorscheme = colorscheme
  end
end

--- Hot-swap: omarchy staged a new neovim.lua.
function M.reload()
  vim.schedule(function()
    local spec = read_spec()
    if not spec then return end
    local plugin, colorscheme = parse(spec)
    if not colorscheme then return end

    local previous = active_plugin
    ensure(plugin)
    active_plugin = plugin and plugin.name or active_plugin

    -- Boot already applied this exact theme; re-clearing highlights would
    -- flash an unstyled frame post-launch.
    if vim.g.applied_colorscheme == colorscheme then return end

    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end

    -- Drop the previous theme's lua modules so its colors are rebuilt.
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

-- Apply at startup once the UI is idle (M.load already applied synchronously;
-- this is a safety net if the spec was not ready during init).
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    if vim.g.applied_colorscheme == nil then M.load() end
  end,
})

-- Ensure nvim has a server socket so the omarchy hook can remote-send (fallback).
-- The run dir may not exist, so create it first.
if vim.v.servername == "" or vim.v.servername == nil then
  pcall(vim.fn.mkdir, vim.fn.stdpath("run"), "p")
  pcall(vim.fn.serverstart, vim.fn.stdpath("run") .. "/nvim." .. vim.fn.getpid() .. ".0")
end

-- File watcher fallback: if the hook fails (no socket), nvim still hot-reloads
-- when neovim.lua changes.
do
  if uv and theme_path then
    local poll = uv.new_fs_poll()
    if poll then
      poll:start(theme_path, 500, function(err, prev, curr)
        if err then return end
        if prev and curr and curr.mtime and prev.mtime and curr.mtime.sec ~= prev.mtime.sec then
          M.reload()
        end
      end)
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function() pcall(function() poll:stop(); poll:close() end) end,
      })
    end
  end
end

return M
