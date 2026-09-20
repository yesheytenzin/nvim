-- Aggregates every plugin spec module into one list for pack.setup().
-- (The active theme spec is NOT here: lua/plugins/theme.lua is an omarchy-owned
-- symlink handled dynamically by lua/theme.lua.)
local specs = {}

for _, name in ipairs({
  "deps",
  "coding",
  "completion",
  "cpp",
  "editor",
  "git",
  "harpoon",
  "navigation",
  "rails",
  "themes",
  "whichkey",
  "workspace",
}) do
  for _, spec in ipairs(require("plugins." .. name)) do
    specs[#specs + 1] = spec
  end
end

return specs
