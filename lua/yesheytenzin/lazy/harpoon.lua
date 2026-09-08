-- Primeagen's current Harpoon 2 bindings.
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>A",
      function() require("harpoon"):list():prepend() end,
      desc = "Harpoon prepend",
    },
    {
      "<leader>a",
      function() require("harpoon"):list():add() end,
      desc = "Harpoon add",
    },
    {
      "<C-e>",
      function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end,
      desc = "Harpoon menu",
    },
    { "<M-1>", function() require("harpoon"):list():select(1) end, desc = "Harpoon item 1" },
    { "<M-2>", function() require("harpoon"):list():select(2) end, desc = "Harpoon item 2" },
    { "<M-3>", function() require("harpoon"):list():select(3) end, desc = "Harpoon item 3" },
    { "<M-4>", function() require("harpoon"):list():select(4) end, desc = "Harpoon item 4" },
  },
  config = function()
    require("harpoon"):setup()
  end,
}
