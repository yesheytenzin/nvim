-- Aggregates every plugin spec module into one list for pack.setup().
-- (The active theme spec is NOT here: lua/custom/omarchy_theme.lua reads the
-- omarchy-managed neovim.lua at runtime and installs that theme itself.)
local specs = {}

for _, name in ipairs({
  "deps",
  "ui",
  "lsp",
  "completion",
  "treesitter",
  "editor",
  "git",
  "harpoon",
  "navigation",
  "rails",
  "themes",
  "whichkey",
  "workspace",
}) do
  for _, spec in ipairs(require("custom.plugins." .. name)) do
    specs[#specs + 1] = spec
  end
end

return specs
