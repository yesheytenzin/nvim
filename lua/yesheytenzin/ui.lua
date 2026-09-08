-- Keep built-in netrw and ColorColumn aligned with whichever theme is active.
local function sync_theme_highlights()
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

  local links = {
    ColorColumn = "CursorLine",
    netrwDir = "Directory",
    netrwClassify = "Delimiter",
    netrwTreeBar = "NonText",
    netrwExe = "String",
    netrwSymLink = "Identifier",
    netrwHide = "Comment",
  }

  for target, source in pairs(links) do
    vim.api.nvim_set_hl(0, target, { link = source })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("YesheytenzinUI", { clear = true }),
  callback = sync_theme_highlights,
})

sync_theme_highlights()
