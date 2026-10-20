-- Harpoon 2 with LazyVim-style bindings.
return {
  {
    "ThePrimeagen/harpoon",
    version = "harpoon2",
    deps = { "plenary.nvim" },
    keys = {
      {
        "<leader>H",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon add",
      },
      {
        "<leader>h",
        function()
          local width = math.max(vim.api.nvim_win_get_width(0) - 4, 1)
          require("harpoon").ui:toggle_quick_menu(require("harpoon"):list(), {
            ui_fallback_width = width,
            ui_width_ratio = 1,
            ui_max_width = width,
          })
        end,
        desc = "Harpoon menu",
      },
      {
        "<leader>1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Harpoon item 1",
      },
      {
        "<leader>2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Harpoon item 2",
      },
      {
        "<leader>3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Harpoon item 3",
      },
      {
        "<leader>4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Harpoon item 4",
      },
      {
        "<leader>5",
        function()
          require("harpoon"):list():select(5)
        end,
        desc = "Harpoon item 5",
      },
      {
        "<leader>6",
        function()
          require("harpoon"):list():select(6)
        end,
        desc = "Harpoon item 6",
      },
      {
        "<leader>7",
        function()
          require("harpoon"):list():select(7)
        end,
        desc = "Harpoon item 7",
      },
      {
        "<leader>8",
        function()
          require("harpoon"):list():select(8)
        end,
        desc = "Harpoon item 8",
      },
      {
        "<leader>9",
        function()
          require("harpoon"):list():select(9)
        end,
        desc = "Harpoon item 9",
      },
    },
    config = function()
      require("harpoon"):setup({
        settings = { save_on_toggle = true },
      })
    end,
  },
}
