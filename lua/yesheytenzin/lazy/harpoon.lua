return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function() require("harpoon"):setup({ settings = { save_on_toggle = true } }) end,
  keys = {
    { "<leader>ha", function() local h=require("harpoon"); if h:list():length()<4 then h:list():add() else vim.notify("Harpoon full (4 max)", vim.log.levels.WARN) end end, desc = "Harpoon add" },
    { "<leader>hm", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
    { "<leader>h1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
    { "<leader>h2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
    { "<leader>h3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
    { "<leader>h4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    { "<leader>hc", function()
      local ok, harpoon = pcall(require, "harpoon")
      if not ok then return end
      -- Close quick menu if open (it has modifiable off, clear would fail inside it)
      pcall(function() harpoon.ui:close_menu() end)
      local list = harpoon:list()
      list:clear()
      -- also clear persisted data file if needed
      vim.notify("Harpoon cleared ("..tostring(list:length()).." items)")
    end, desc = "Harpoon clear" },
  },
}
