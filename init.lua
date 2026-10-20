vim.loader.enable()

require("custom.options")
require("custom.keymaps")

require("custom.autocmds")
require("custom.terminal")
require("custom.remote_clipboard")
require("custom.toolchain")

require("custom.pack").setup(require("custom.plugins"))

require("custom.omarchy_theme").load()

vim.api.nvim_create_user_command("ConfigReload", function(opts)
  if require("custom.pack").load("plenary.nvim") then
    require("plenary.reload").reload_module(opts.args)
  end
end, { nargs = 1, desc = "Reload a Lua config module" })
