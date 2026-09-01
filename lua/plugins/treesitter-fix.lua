-- Fix for nvim-treesitter diff parser mismatch: disable treesitter highlight for diff
-- Original plugin query has (change) etc which doesn't match installed parser ABI 15
-- Using after/queries override caused local changes; disable instead and use classic vim highlight
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    highlight = {
      disable = { "diff" },
    },
  },
}
