-- Completion: blink.cmp (the successor to nvim-cmp). The built-in lsp / path /
-- snippets / buffer sources replace the whole nvim-cmp source-plugin stack, and
-- the built-in `snippets` source loads friendly-snippets via native
-- `vim.snippet` — so LuaSnip is not needed.
--
-- Pinned to 1.*: blink v2 (main) requires the separate compiled `blink.lib`
-- package; v1 is the stable line.
return {
  { "rafamadriz/friendly-snippets" },
  {
    "saghen/blink.cmp",
    version = vim.version.range("1.*"),
    event = { "InsertEnter", "CmdlineEnter" },
    deps = { "friendly-snippets" },
    config = function()
      require("blink.cmp").setup({
        keymap = {
          -- super-tab: Tab selects-and-accepts / jumps snippets (matches the
          -- old cmp setup); C-p/C-n select, C-Space show, C-e hide, C-k signature.
          preset = "super-tab",
          -- cmp confirmed on <CR>; super-tab leaves <CR> unbound.
          ["<CR>"] = { "accept", "fallback" },
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          providers = {
            lsp = { max_items = 20 },
            snippets = { max_items = 10 },
            -- Buffer rescans open buffers per keystroke: gate on 3+ chars and
            -- cap items to keep typing latency flat in large files.
            buffer = { min_keyword_length = 3, max_items = 12 },
            path = { min_keyword_length = 2, max_items = 12 },
          },
        },
        cmdline = {
          keymap = { preset = "cmdline" },
          completion = { menu = { auto_show = true } },
        },
      })
    end,
  },
}
