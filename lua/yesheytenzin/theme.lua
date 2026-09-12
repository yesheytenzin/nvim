-- Omarchy theme bridge: lazy applies colorscheme from ~/.local/state/omarchy/current/theme/neovim.lua
-- Called via omarchy hook: nvim --server $sock --remote-send "<cmd>lua require('yesheytenzin.theme').reload()<CR>"
-- Also auto-applied at startup via VeryLazy
local M = {}

local function get_omarchy_colorscheme()
  local ok, spec = pcall(require, "yesheytenzin.lazy.theme")
  if not ok or type(spec) ~= "table" then return nil end
  -- Omarchy's generated theme file may include a disabled LazyVim marker.
  for _, s in ipairs(spec) do
    if s[1] == "LazyVim/LazyVim" and s.opts and s.opts.colorscheme then
      return s.opts.colorscheme
    end
  end
  -- Fallback: pure lazy without LazyVim, try to infer from first plugin
  -- e.g. { "rebelot/kanagawa.nvim" } -> colorscheme "kanagawa"
  --      { "catppuccin/nvim" } -> "catppuccin"
  --      { "folke/tokyonight.nvim" } -> "tokyonight-night"
  local first = spec[1]
  if first and type(first[1]) == "string" then
    local repo = first[1]:lower()
    if repo:find("kanagawa") then return "kanagawa" end
    if repo:find("catppuccin") then return "catppuccin" end
    if repo:find("tokyonight") then return "tokyonight-night" end
    if repo:find("gruvbox") then return "gruvbox" end
    if repo:find("rose%-pine") then return "rose-pine-dawn" end
  end
  return nil
end

local function apply_colorscheme(name, plugin_name)
  if not name then return false end
  -- Ensure plugin is installed/loaded via lazy
  if plugin_name then
    local ok, cfg = pcall(require, "lazy.core.config")
    if ok and cfg and cfg.plugins and cfg.plugins[plugin_name] then
      local plugin = cfg.plugins[plugin_name]
      if plugin and not plugin._.loaded then
        local ok2, loader = pcall(require, "lazy.core.loader")
        if ok2 and loader then pcall(loader.colorscheme, name) end
      elseif plugin and plugin._.loaded then
        local ok2, loader = pcall(require, "lazy.core.loader")
        if ok2 and loader and loader.reload then pcall(loader.reload, plugin) end
      end
    end
  end
  -- Apply colorscheme
  local ok = pcall(vim.cmd.colorscheme, name)
  if ok then
    vim.g.colors_name = name
    -- Also try to notify lazy that colorscheme changed
    pcall(vim.api.nvim_exec_autocmds, "ColorScheme", { pattern = name })
    return true
  end
  return false
end

function M.reload()
  -- Reload theme spec from disk (omarchy just staged new neovim.lua)
  package.loaded["yesheytenzin.lazy.theme"] = nil
  vim.schedule(function()
    local ok, spec = pcall(require, "yesheytenzin.lazy.theme")
    if not ok then
      return
    end
    -- Find theme plugin name (first spec not LazyVim)
    local theme_plugin, colorscheme
    for _, s in ipairs(spec) do
      if s[1] == "LazyVim/LazyVim" and s.opts and s.opts.colorscheme then
        colorscheme = s.opts.colorscheme
      elseif s[1] and s[1] ~= "LazyVim/LazyVim" then
        theme_plugin = s.name or s[1]
        -- for "catppuccin/nvim" the plugin key is "catppuccin"
        if theme_plugin == "catppuccin/nvim" then theme_plugin = "catppuccin" end
        if theme_plugin:find("/") then theme_plugin = theme_plugin:match("[^/]+$") end
      end
    end
    if not colorscheme then colorscheme = get_omarchy_colorscheme() end
    if not colorscheme then
      return
    end

    -- Boot already applied this exact theme synchronously (see lazy_init):
    -- re-clearing highlights here would flash an unstyled frame post-launch.
    if vim.g.yesheytenzin_applied_theme == colorscheme then
      return
    end

    -- Clear old highlights (needed for light/dark switches)
    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end

    -- Unload previous theme lua modules if aether-style (generic template)
    if theme_plugin then
      local ok2, cfg = pcall(require, "lazy.core.config")
      if ok2 and cfg and cfg.plugins then
        local p = cfg.plugins[theme_plugin]
        if p and p.dir then
          local ok3, util = pcall(require, "lazy.core.util")
          if ok3 and util and util.walkmods then
            util.walkmods(p.dir .. "/lua", function(mod)
              package.loaded[mod] = nil
              package.preload[mod] = nil
            end)
          end
        end
      end
    end

    if apply_colorscheme(colorscheme, theme_plugin) then
      vim.g.yesheytenzin_applied_theme = colorscheme
    end
    vim.defer_fn(function()
      if pcall(vim.cmd.colorscheme, colorscheme) then
        vim.g.yesheytenzin_applied_theme = colorscheme
      end
      vim.cmd("redraw!")
      -- Reload transparency if user had it (optional)
      local transp = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"
      if vim.fn.filereadable(transp) == 1 then
        vim.defer_fn(function() pcall(vim.cmd, "source " .. transp) end, 5)
      end
    end, 10)
  end)
end

-- Auto-apply omarchy theme at startup (VeryLazy, after lazy done)
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function() M.reload() end,
})



-- Ensure nvim has a server socket so omarchy hook can remote-send (fallback).
-- The run dir may not exist (then serverstart fails with "operation not
-- permitted" spam in nvim.log), so create it first.
if vim.v.servername == "" or vim.v.servername == nil then
  pcall(vim.fn.mkdir, vim.fn.stdpath("run"), "p")
  pcall(vim.fn.serverstart, vim.fn.stdpath("run") .. "/nvim." .. vim.fn.getpid() .. ".0")
end

-- File watcher fallback: if hook fails (no socket), nvim still hot-reloads when neovim.lua changes
do
  local theme_path = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
  local uv = vim.uv or vim.loop
  if uv and theme_path then
    local poll = uv.new_fs_poll()
    if poll then
      poll:start(theme_path, 500, function(err, prev, curr)
        if err then return end
        if prev and curr and curr.mtime and prev.mtime and curr.mtime.sec ~= prev.mtime.sec then
          vim.schedule(function()
            local ok, mod = pcall(require, "yesheytenzin.theme")
            if ok and mod and mod.reload then mod.reload() end
          end)
        end
      end)
      -- keep handle alive
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function() pcall(function() poll:stop(); poll:close() end) end,
      })
    end
  end
end

return M
