-- Faster which-key: minimal, 80ms delay for <leader>ha etc (was 200-300, now 80)
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    delay = 80, -- faster recog (was 200) — set to false to disable entirely
    triggers = { { "<auto>", mode = "nxsot" } },
    -- right side vertical (was bottom: row=math.huge). col=math.huge = right edge
    win = {
      border = "single",
      no_overlap = true,
      padding = { 1, 2 },
      title = true,
      title_pos = "center",
      row = 0,
      col = math.huge,
      width = 32,
      height = { min = 4, max = 35 },
      zindex = 1000,
      wo = { winblend = 0 },
    },
    layout = { width = { min = 20 }, spacing = 3 },
  },
}
