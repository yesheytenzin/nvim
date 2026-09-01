-- Neoscroll: smooth scrolling for a less disorienting vertical motion
-- https://github.com/karb94/neoscroll.nvim
-- Keeps ThePrimagen's zz-centering + scrolloff=8, adds mouse-like smooth easing
return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  opts = {
    -- keys with smooth animation (C-u/C-d handled manually below to add zz centering)
    mappings = { "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
    hide_cursor = true, -- hide cursor during animation (less flicker)
    stop_eof = true, -- stop at EOF
    respect_scrolloff = false, -- set true to honor vim.opt.scrolloff=8 DURING animation
    cursor_scrolls_alone = true,
    easing = "sine", -- smooth ease (try "cubic", "quadratic", "circular")
    pre_hook = nil,
    post_hook = nil,
    performance_mode = false,
  },
  config = function(_, opts)
    local neoscroll = require("neoscroll")
    neoscroll.setup(opts)

    -- Re-apply ThePrimagen centering ON TOP of smooth scroll.
    -- neoscroll already mapped <C-u>/<C-d> to smooth versions; we wrap them
    -- to add zz after the animation so the cursor stays in the middle.
    local duration = 200
    local function smooth_centered(motion)
      return function()
        motion({ duration = duration, easing = opts.easing or "sine" })
        vim.defer_fn(function()
          -- use normal! zz without affecting jumplist
          vim.cmd("normal! zz")
        end, duration + 30)
      end
    end

    vim.keymap.set("n", "<C-u>", smooth_centered(neoscroll.ctrl_u), { desc = "Half page up (centered, smooth)" })
    vim.keymap.set("n", "<C-d>", smooth_centered(neoscroll.ctrl_d), { desc = "Half page down (centered, smooth)" })
  end,
}
