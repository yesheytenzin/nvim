-- Better blink menu: Omarchy-aware, spacious, informative (keeps single border for insert)
return {
  "saghen/blink.cmp",
  version = "*",
  event = "InsertEnter",
  dependencies = { "saghen/blink.lib", "rafamadriz/friendly-snippets" },
  opts = {
    keymap = { preset = "enter", ["<C-y>"] = { "select_and_accept" } },
    cmdline = { enabled = false }, -- : stays native (winborder=none)
    appearance = {
      nerd_font_variant = "mono",
      use_nvim_cmp_as_default = true,
      kind_icons = {
        -- keep LazyVim defaults, just ensure aligned mono
      },
    },
    completion = {
      menu = {
        border = "single",
        winblend = 0,
        winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
        scrollbar = true,
        scrolloff = 2,
        max_height = 10,
        min_width = 18,
        direction_priority = { "s", "n" },
        draw = {
          align_to = "label",
          padding = 1,
          gap = 1,
          treesitter = { "lsp" },
          columns = {
            { "kind_icon", gap = 1 },
            { "label", "label_description", gap = 1 },
            { "source_name" },
          },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          border = "single",
          winblend = 0,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder",
          max_height = 12,
        },
      },
      ghost_text = { enabled = false },
      list = { selection = { preselect = true, auto_insert = false } },
    },
    signature = { enabled = false },
  },
}
