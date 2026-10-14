-- Startup orchestration: options -> keymaps (leader before plugins) ->
-- plugin setup -> behavior. Each module owns its own deferred work (VeryLazy
-- hooks, file watchers); this file only orders the requires.
require("options")
require("keymaps")

-- Native plugin manager (vim.pack + trigger-loaded specs).
require("pack").setup(require("plugins"))

-- Self-registers its deferred setup on VeryLazy; safe to require eagerly.
require("remote_clipboard")
require("autocmds")
require("terminal")

-- Install + apply the omarchy theme SYNCHRONOUSLY so the first paint is
-- already themed (no unstyled flash on launch).
require("theme").load()

-- Dev helper: :lua R("keymaps") to hot-reload one module.
function R(name)
  require("pack").load("plenary.nvim")
  require("plenary.reload").reload_module(name)
end
