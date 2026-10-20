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
          preset = "enter",
          ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
        },
        completion = {
          list = { selection = { preselect = false, auto_insert = false } },
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          per_filetype = { ruby = { inherit_defaults = true, "ruby_defs" } },
          providers = {
            lsp = {
              max_items = 20,
              score_offset = 4,
              transform_items = function(ctx, items)
                return require("custom.blink_ruby_defs").drop_lsp_duplicates(ctx, items)
              end,
            },
            ruby_defs = { name = "Ruby", module = "custom.blink_ruby_defs", score_offset = 4 },
            snippets = { max_items = 10 },
            buffer = {
              min_keyword_length = 3,
              max_items = 12,
              transform_items = function(ctx, items)
                return require("custom.blink_ruby_defs").drop_buffer_duplicates(ctx, items)
              end,
            },
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
