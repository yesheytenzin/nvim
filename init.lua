-- Startup orchestration: options -> keymaps (leader before plugins) ->
-- plugin manager -> behavior. Each module owns its own deferred work
-- (VeryLazy hooks, file watchers); this file only orders the requires.
require("options")
require("keymaps")
require("lazy_init")

-- Self-registers its deferred setup on VeryLazy; safe to require eagerly.
require("remote_clipboard")
require("autocmds")

-- Keep the Omarchy theme bridge loaded after the plugin manager is ready.
pcall(require, "theme")

-- Dev helper: :lua R("keymaps") to hot-reload one module.
function R(name)
  require("plenary.reload").reload_module(name)
end
