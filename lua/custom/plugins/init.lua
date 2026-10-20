local specs = {}

for _, name in ipairs({
  "deps",
  "ui",
  "formatting",
  "tooling",
  "lsp",
  "completion",
  "debug",
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
