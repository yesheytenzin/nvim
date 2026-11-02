local M = {}

-- plugin dir -> colorschemes it provides. Dirs already exist under
-- site/pack/core/opt (see nvim-pack-lock.json). We packadd on demand so
-- the picker works without eager-loading every theme at startup.
local THEMES = {
  { dir = "flexoki-neovim", schemes = { "flexoki-light", "flexoki-dark", "flexoki" } },
  { dir = "kanagawa.nvim", schemes = { "kanagawa", "kanagawa-wave", "kanagawa-dragon", "kanagawa-lotus" } },
  { dir = "gruvbox.nvim", schemes = { "gruvbox" } },
  { dir = "rose-pine", schemes = { "rose-pine", "rose-pine-moon", "rose-pine-main", "rose-pine-dawn" } },
  { dir = "tokyonight.nvim", schemes = { "tokyonight", "tokyonight-night", "tokyonight-storm", "tokyonight-moon", "tokyonight-day" } },
  { dir = "aether", schemes = { "aether" } },
  { dir = "everforest-nvim", schemes = { "everforest" } },
}

local function ensure_all()
  for _, t in ipairs(THEMES) do
    pcall(vim.cmd.packadd, t.dir)
  end
end

local function apply(scheme)
  ensure_all()
  local ok = pcall(vim.cmd.colorscheme, scheme)
  if ok then
    -- Tell omarchy watcher this is intentional so it doesn't fight back.
    vim.g.applied_colorscheme = scheme
  else
    vim.notify("theme: cannot apply " .. scheme, vim.log.levels.ERROR)
  end
  return ok
end

function M.list()
  local out = {}
  for _, t in ipairs(THEMES) do
    for _, s in ipairs(t.schemes) do
      out[#out + 1] = s
    end
  end
  return out
end

function M.pick()
  ensure_all()
  -- fzf-lua gives live preview out of the box (applies on cursor move).
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and fzf and fzf.colorschemes then
    -- Load fzf-lua lazily if needed (it's cmd/keys-lazy in navigation.lua).
    pcall(vim.cmd, "packadd fzf-lua")
    local ok2, fzf2 = pcall(require, "fzf-lua")
    if ok2 and fzf2.colorschemes then
      fzf2.colorschemes({
        -- Keep our choice sticky for the omarchy watcher.
        actions = {
          ["default"] = function(selected)
            local scheme = selected and selected[1]
            if scheme then
              apply(scheme)
            end
          end,
        },
      })
      return
    end
  end
  -- Fallback: vim.ui.select (no live preview, but always works).
  vim.ui.select(M.list(), { prompt = "Theme:" }, function(choice)
    if choice then
      apply(choice)
    end
  end)
end

M.apply = apply

-- :Theme [name] — no arg opens picker, arg applies directly with completion.
vim.api.nvim_create_user_command("Theme", function(opts)
  if opts.args and opts.args ~= "" then
    apply(opts.args)
  else
    M.pick()
  end
end, {
  nargs = "?",
  complete = function()
    return M.list()
  end,
  desc = "Live theme switch (picker or :Theme <name>)",
})

return M
