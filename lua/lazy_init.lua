local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

if vim.loader then vim.loader.enable() end

if not uv.fs_stat(lazypath) then
  local output = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim:\n" .. output)
  end
end

vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { lazy = true, version = false },
  install = { colorscheme = { "rose-pine-dawn" } },
  change_detection = { enabled = false, notify = false },
  checker = { enabled = false, notify = false },
  performance = {
    cache = { enabled = true },
    reset_packpath = true,
    rtp = { disabled_plugins = { "gzip", "matchit", "matchparen", "rplugin", "spellfile", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})

-- Apply the persisted colorscheme SYNCHRONOUSLY now, not on VeryLazy, so the
-- first paint is already themed (no unstyled flash on launch). Reads the
-- omarchy-managed spec dynamically, so external theme switches keep working.
-- Cost is one theme plugin load (~ms); the VeryLazy bridge still handles
-- hot-reload afterwards.
do
  local colorscheme
  local ok, spec = pcall(require, "plugins.theme")
  if ok and type(spec) == "table" then
    for _, s in ipairs(spec) do
      if s[1] == "LazyVim/LazyVim" and s.opts and s.opts.colorscheme then
        colorscheme = s.opts.colorscheme
        break
      end
    end
  end
  if colorscheme then
    -- loader.colorscheme() only ENSURES the owning plugin is loaded, it never
    -- applies anything (application happens via the :colorscheme command it
    -- was intercepting). So load, then apply explicitly.
    local ok_loader, loader = pcall(require, "lazy.core.loader")
    if ok_loader and loader and loader.colorscheme then
      pcall(loader.colorscheme, colorscheme)
    end
    if pcall(vim.cmd.colorscheme, colorscheme) then
      vim.g.applied_colorscheme = colorscheme
    end
  end
end

-- Conceal the per-plugin keybind triggers in the :Lazy home view.
-- lazy.nvim hard-codes the trigger column (keys/cmd/event/ft) with no toggle,
-- so paint LazyReasonKeys in the float background instead. Safe against
-- lazy's own highlight pass (it uses `default = true`, which never overrides
-- an explicitly set group). Recomputed on ColorScheme so Omarchy
-- light/dark switches keep it invisible. Known artifact: the cursor row's
-- CursorLine background still reveals the keys on the focused line only.
do
  local group = vim.api.nvim_create_augroup("ConfigLazyUi", { clear = true })
  local function conceal_lazy_keys()
    local bg = vim.api.nvim_get_hl(0, { name = "NormalFloat" }).bg
      or vim.api.nvim_get_hl(0, { name = "Normal" }).bg
    if bg then
      vim.api.nvim_set_hl(0, "LazyReasonKeys", { fg = bg, bg = bg })
    end
  end
  conceal_lazy_keys()
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = conceal_lazy_keys })
end
