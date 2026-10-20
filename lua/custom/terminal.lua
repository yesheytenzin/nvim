local M = {}

local term_buf = nil
local term_win = nil

local function alive()
  return term_buf
    and vim.api.nvim_buf_is_valid(term_buf)
    and vim.fn.jobwait({ vim.b[term_buf].terminal_job_id }, 0)[1] == -1
end

function M.toggle()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
    return
  end
  if alive() then
    vim.cmd("belowright sbuffer " .. term_buf)
  else
    vim.cmd("belowright 12new")
    term_buf = vim.api.nvim_get_current_buf()
    local shell = os.getenv("SHELL") or vim.o.shell
    local ok, job = pcall(vim.fn.jobstart, { shell }, { term = true })
    if not ok or job <= 0 then
      term_buf = nil
      vim.notify(("terminal: failed to start %s: %s"):format(shell, job), vim.log.levels.ERROR)
      vim.cmd("close")
      return
    end
  end
  term_win = vim.api.nvim_get_current_win()
  vim.cmd("startinsert")
end

function M.run(cmd)
  local origin = vim.api.nvim_get_current_win()
  if not (term_win and vim.api.nvim_win_is_valid(term_win)) then
    M.toggle()
  end
  if not alive() then
    return
  end
  vim.fn.chansend(vim.b[term_buf].terminal_job_id, "clear; " .. cmd .. "\r")
  vim.api.nvim_win_call(term_win, function()
    vim.cmd("normal! G")
  end)
  vim.cmd("stopinsert")
  vim.api.nvim_set_current_win(origin)
end

local group = vim.api.nvim_create_augroup("ConfigTerminal", { clear = true })

vim.api.nvim_create_autocmd("TermOpen", {
  group = group,
  callback = function(e)
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    local opts = { buffer = e.buf, silent = true }
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
    vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
    vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
    vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
    vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)
    vim.keymap.set("t", "<C-/>", function()
      vim.cmd("stopinsert")
      M.toggle()
    end, opts)
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(e)
    if tonumber(e.match) == term_win then
      term_win = nil
    end
  end,
})

vim.keymap.set("n", "<C-/>", M.toggle, { desc = "Terminal toggle (split)" })

return M
