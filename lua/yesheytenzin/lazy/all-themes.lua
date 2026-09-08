return { -- optional extra themes for :colorscheme (lazy, not loaded)
  -- Rails API + C++: keep 1 extra for fallback only (was 6 -> 2, saves ~1ms spec + memory)
  { "folke/tokyonight.nvim", lazy = true, priority = 1000 },
  { "rebelot/kanagawa.nvim", lazy = true, priority = 1000 },
}
