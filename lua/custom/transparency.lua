-- Transparent background so Ghostty's background-opacity shows through.
-- Re-applied on every ColorScheme (Omarchy theme switches, :Theme, etc).
local M = {}

vim.g.transparent = true

local GROUPS = {
  -- core
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "SignColumn",
  "FoldColumn",
  "Folded",
  "EndOfBuffer",
  "LineNr",
  "LineNrAbove",
  "LineNrBelow",
  "CursorLineNr",
  "CursorLine",
  "CursorLineSign",
  "CursorLineFold",
  "WinSeparator",
  "VertSplit",
  "StatusLine",
  "StatusLineNC",
  "TabLine",
  "TabLineFill",
  "TabLineSel",
  "WinBar",
  "WinBarNC",
  -- popup menu / completion
  "Pmenu",
  "PmenuSel",
  "PmenuSbar",
  "PmenuThumb",
  -- telescope
  "TelescopeNormal",
  "TelescopeBorder",
  "TelescopePromptNormal",
  "TelescopePromptBorder",
  "TelescopeResultsNormal",
  "TelescopeResultsBorder",
  "TelescopePreviewNormal",
  "TelescopePreviewBorder",
  "TelescopeTitle",
  "TelescopePromptTitle",
  "TelescopeResultsTitle",
  "TelescopePreviewTitle",
  -- fzf-lua
  "FzfLuaNormal",
  "FzfLuaBorder",
  "FzfLuaTitle",
  "FzfLuaPreviewNormal",
  "FzfLuaPreviewBorder",
  "FzfLuaPrompt",
  -- blink.cmp
  "BlinkCmpMenu",
  "BlinkCmpMenuBorder",
  "BlinkCmpMenuSelection",
  "BlinkCmpDoc",
  "BlinkCmpDocBorder",
  "BlinkCmpSignatureHelp",
  -- which-key / lazy / mason / misc floats
  "WhichKeyFloat",
  "LazyNormal",
  "MasonNormal",
  "NotifyBackground",
  "NoiceNormal",
  "NoiceFloat",
  -- git / diff UI keeps readable fg, just drops bg
  "GitSignsAdd",
  "GitSignsChange",
  "GitSignsDelete",
  "DiagnosticSignError",
  "DiagnosticSignWarn",
  "DiagnosticSignInfo",
  "DiagnosticSignHint",
}

function M.apply()
  if not vim.g.transparent then
    return
  end
  for _, name in ipairs(GROUPS) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl then
      -- Preserve fg / styling, drop only the background.
      hl.bg = nil
      hl.ctermbg = nil
      -- `blend` keeps floats composited; Ghostty already handles opacity.
      pcall(vim.api.nvim_set_hl, 0, name, hl)
    end
  end
end

function M.toggle()
  vim.g.transparent = not vim.g.transparent
  if vim.g.transparent then
    M.apply()
  else
    -- Reload colorscheme to restore backgrounds.
    local cs = vim.g.colors_name
    if cs then
      vim.cmd.colorscheme(cs)
    end
  end
  vim.notify("transparency: " .. (vim.g.transparent and "on" or "off"))
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("GhosttyTransparency", { clear = true }),
  callback = function()
    -- Defer one tick so theme setup finishing after ColorScheme still gets cleared.
    vim.schedule(M.apply)
  end,
})

vim.api.nvim_create_user_command("TransparentToggle", M.toggle, { desc = "Toggle transparent background" })

-- Apply on startup too (after Omarchy theme load).
vim.schedule(M.apply)

return M
