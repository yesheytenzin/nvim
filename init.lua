--[[
  Personal Neovim configuration, built on kickstart.nvim.

  Layout:
    lua/custom/options.lua       core options (Primeagen defaults + perf)
    lua/custom/keymaps.lua       global keymaps
    lua/custom/autocmds.lua      project root, indents, big files, trim
    lua/custom/pack.lua          vim.pack + trigger-based lazy loading
    lua/custom/plugins/*.lua     plugin specs, aggregated by plugins/init.lua
    lua/custom/lsp/*.lua         LSP attach maps, server policy, Ruby index
    lua/custom/lsp_manifest.lua  servers/tools/gems the toolchain wants
    lua/custom/parser_manifest.lua  Treesitter parsers wanted
    lua/custom/toolchain.lua     :Toolchain (wanted vs installed)
    lua/custom/health.lua        :checkhealth custom
    lua/examples/*.lua           optional kickstart setups, not loaded

  First run on a new machine:
    scripts/bootstrap.sh   prefetch parsers + Mason servers/tools
    scripts/verify.sh      prove plugins, parsers, LSPs and lockfile

  Update plugins with :lua vim.pack.update() — vim.pack is Lua-only.
  Add a spec module under lua/custom/plugins/ and list it in plugins/init.lua.
--]]

-- Cache compiled Lua modules for faster startup.
vim.loader.enable()

-- Options and leader keys must exist before any plugin loads.
require("custom.options")
require("custom.keymaps")

-- Behavior modules that register autocmds/commands. They are independent of
-- the plugin loader, but load before it so file-read guards are in place.
require("custom.autocmds")
require("custom.terminal")
require("custom.remote_clipboard")
require("custom.toolchain")

-- Native plugin manager (vim.pack) with keys/cmd/ft/event triggers.
require("custom.pack").setup(require("custom.plugins"))

-- Install + apply the omarchy theme synchronously so the first paint is
-- already themed (no unstyled flash on launch). Falls back to rose-pine in
-- lua/custom/plugins/themes.lua when omarchy has no active theme.
require("custom.omarchy_theme").load()

vim.api.nvim_create_user_command("ConfigReload", function(opts)
  if require("custom.pack").load("plenary.nvim") then
    require("plenary.reload").reload_module(opts.args)
  end
end, { nargs = 1, desc = "Reload a Lua config module" })

-- Optional setups inherited from kickstart live under lua/examples/. They
-- register plugins with vim.pack directly, bypassing the lazy loader above,
-- so they are examples to copy from rather than part of this config:
--   require 'examples.debug'
--   require 'examples.indent_line'
--   require 'examples.lint'
--   require 'examples.autopairs'
--   require 'examples.neo-tree'

-- vim: ts=2 sts=2 sw=2 et
