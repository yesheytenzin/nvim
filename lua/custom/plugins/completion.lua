return {
  { "rafamadriz/friendly-snippets" },
  {
    "saghen/blink.cmp",
    version = vim.version.range("1.*"),
    event = { "InsertEnter", "CmdlineEnter" },
    deps = { "friendly-snippets" },
    config = function()
      require("blink.cmp").setup({
        appearance = { nerd_font_variant = "mono" },
        keymap = {
          preset = "enter",
          ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
          ["<C-k>"] = { "show_documentation", "hide_documentation", "fallback" },
          ["<C-d>"] = { "scroll_documentation_down", "fallback" },
          ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        },
        completion = {
          menu = {
            border = "single",
            scrollbar = false,
            direction_priority = { "s", "n" },
            draw = {
              columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
              treesitter = { "lsp" },
            },
          },
          list = {
            selection = { preselect = false, auto_insert = false },
            max_items = 30,
          },
          -- Local DSL docs are cheap; LSP docs arrive async. Small delay
          -- keeps `belongs_to` discoverable without per-keystroke lag.
          documentation = { auto_show = true, auto_show_delay_ms = 250, window = { border = "single", scrollbar = false } },
          trigger = { show_on_keyword = true, show_on_trigger_character = true },
        },
        fuzzy = { implementation = "prefer_rust_with_warning" },
        signature = { enabled = false },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          per_filetype = {
            ruby = { inherit_defaults = true, "ruby_defs" },
            eruby = { inherit_defaults = true, "ruby_defs" },
          },
          providers = {
            lsp = {
              max_items = 20,
              score_offset = 4,
              transform_items = function(ctx, items)
                return require("custom.blink_ruby_defs").drop_lsp_duplicates(ctx, items)
              end,
            },
            ruby_defs = {
              name = "Ruby",
              module = "custom.blink_ruby_defs",
              score_offset = 4,
              -- Instant treesitter scan: show after 1 char so fresh defs
              -- appear immediately after :w / reopen, without LSP index wait.
              min_keyword_length = 1,
              -- Static Rails DSL (~200 items); blink fuzzy-sorts before
              -- truncating, so a typed prefix still ranks correctly.
              max_items = 50,
            },
            snippets = { max_items = 10 },
            buffer = {
              -- Was 3: short func names never completed from buffer fallback.
              min_keyword_length = 2,
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
          completion = { menu = { auto_show = true, border = "single" } },
        },
      })
    end,
  },
}
