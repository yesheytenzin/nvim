require("yesheytenzin.set")
require("yesheytenzin.remap")
require("yesheytenzin.lazy_init")

-- Personal behavior layered onto the Primeagen base.
require("yesheytenzin.autocmds")
require("yesheytenzin.keymaps")

-- Keep the Omarchy theme bridge loaded after the plugin manager is ready.
pcall(require, "yesheytenzin.theme")

vim.filetype.add({
  extension = {
    templ = "templ",
  },
})

function R(name)
  require("plenary.reload").reload_module(name)
end
