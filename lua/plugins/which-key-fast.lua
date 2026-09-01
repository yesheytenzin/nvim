-- Faster which-key: minimal, 80ms delay for <leader>ha etc (was 200-300, now 80)
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    delay = 80, -- faster recog (was 200)
    triggers = { { "<auto>", mode = "nxsot" } },
    win = { border = "single" },
  },
}
