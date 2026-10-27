local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

assert(vim.g.colors_name == "aether", "Run with Still active")
local normal = highlight("Normal")
local bar = highlight("StatusLine")
local mode = highlight("MiniStatuslineModeNormal")

local function check_still()
  local filename = highlight("MiniStatuslineFilename")
  assert(filename.fg == normal.fg and filename.bg == bar.bg, "Filename must use readable text on slate")
  assert(filename.fg ~= filename.bg, "Filename must not disappear into its background")
  for _, name in ipairs({ "MiniStatuslineDevinfo", "MiniStatuslineFileinfo", "MiniStatuslineInactive" }) do
    local info = highlight(name)
    assert(info.bg == bar.bg and info.fg ~= info.bg, name)
  end
  assert(vim.deep_equal(mode, highlight("MiniStatuslineModeNormal")), "Keep the mode indicator unchanged")
end

check_still()
vim.cmd.colorscheme("aether")
check_still()
vim.g.colors_name = "other"
vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { fg = 0x123456, bg = 0x654321 })
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "other" })
assert(highlight("MiniStatuslineFilename").fg == 0x123456, "Do not override other colorschemes")
vim.cmd.colorscheme("aether")
check_still()
print("PASS Still statusline startup, colorscheme reload, mode indicator, and other-colorscheme isolation")
