local function harpoon_list()
  return require("harpoon"):list()
end

local function warn(message)
  vim.notify("Harpoon: " .. message, vim.log.levels.WARN)
end

local function addable_buffer()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    warn("current buffer has no file, nothing to mark")
    return false
  end
  if vim.fn.isdirectory(name) == 1 then
    warn("current buffer is a directory, nothing to mark")
    return false
  end
  return true
end

return {
  {
    "ThePrimeagen/harpoon",
    version = "harpoon2",
    deps = { "plenary.nvim" },
    keys = {
      {
        "<leader>ha",
        function()
          if addable_buffer() then
            harpoon_list():add()
          end
        end,
        desc = "Harpoon add",
      },
      {
        "<leader>hm",
        function()
          local list = harpoon_list()
          -- harpoon leaves a stale length when its menu closes on a blank line
          if list:length() > 0 and next(list.items) == nil then
            list:clear()
          end
          local width = math.max(vim.api.nvim_win_get_width(0) - 4, 1)
          require("harpoon").ui:toggle_quick_menu(list, {
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
          harpoon_list():select(1)
        end,
        desc = "Harpoon item 1",
      },
      {
        "<leader>2",
        function()
          harpoon_list():select(2)
        end,
        desc = "Harpoon item 2",
      },
      {
        "<leader>3",
        function()
          harpoon_list():select(3)
        end,
        desc = "Harpoon item 3",
      },
      {
        "<leader>4",
        function()
          harpoon_list():select(4)
        end,
        desc = "Harpoon item 4",
      },
      {
        "<leader>5",
        function()
          harpoon_list():select(5)
        end,
        desc = "Harpoon item 5",
      },
      {
        "<leader>6",
        function()
          harpoon_list():select(6)
        end,
        desc = "Harpoon item 6",
      },
      {
        "<leader>7",
        function()
          harpoon_list():select(7)
        end,
        desc = "Harpoon item 7",
      },
      {
        "<leader>8",
        function()
          harpoon_list():select(8)
        end,
        desc = "Harpoon item 8",
      },
      {
        "<leader>9",
        function()
          harpoon_list():select(9)
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
