-- mergeui.nvim: RubyMine-style 3-pane merge (CURRENT | RESULT | INCOMING) — renamed from tri-merge
return {
  "yesheytenzin/mergeui.nvim",
  cmd = { "MergeUI", "MergeUIClose", "MergeUITakeLeft", "MergeUITakeRight", "MergeUITakeBoth", "MergeUITakeNone", "MergeUIToggle", "MergeUISingle", "MergeUITriple", "TriMerge", "TriMergeClose", "RubymineMerge" },
  keys = {
    { "<leader>gm", "<cmd>MergeUI<cr>", desc = "Merge: 3-pane (CURRENT | RESULT | INCOMING)" },
    -- NOTE: no bare `]c`/`[c` entries: a keys entry without an action creates a
    -- GLOBAL placeholder that swallows the builtin diff motions ]c/[c
    -- everywhere. Conflict navigation stays buffer-local via opts.keymaps.
  },
  opts = {
    view = "triple", -- "triple" (CURRENT|RESULT|INCOMING) or "single" (RESULT only) -- toggle with <leader>mt or :MergeUIToggle,
    keymaps = {
      take_left = "<leader>mh", -- >> CURRENT
      take_right = "<leader>ml", -- << INCOMING
      take_both = "<leader>mb",
      take_none = "<leader>mx",
      next_conflict = "]c",
      prev_conflict = "[c",
      quit = "<leader>mq",
    },
    show_indicators = true,
  },
  config = function(_, opts)
    require("mergeui").setup(opts)
  end,
}
