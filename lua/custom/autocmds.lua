vim.api.nvim_create_autocmd("FileType", {
  pattern = { "ruby", "eruby", "yaml" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("ConfigYankHighlight", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

local AutoCdGroup = vim.api.nvim_create_augroup("ConfigAutoCd", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = AutoCdGroup,
  pattern = "*",
  callback = function(e)
    if vim.bo[e.buf].buftype ~= "" or vim.bo[e.buf].filetype == "netrw" then
      return
    end
    local name = vim.api.nvim_buf_get_name(e.buf)
    if name == "" or name:match("^%w+://") then
      return
    end
    local root = vim.fs.root(e.buf, { ".git", "Gemfile", "compile_commands.json", "CMakeLists.txt" })
    if root and root ~= vim.fn.getcwd(0) then
      vim.cmd.lcd({ args = { root }, mods = { silent = true } })
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = AutoCdGroup,
  pattern = "netrw",
  callback = function(e)
    pcall(vim.keymap.del, "n", "p", { buffer = e.buf })
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave", "FileType" }, {
  group = AutoCdGroup,
  callback = function(e)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(e.buf) and vim.fn.isdirectory(vim.api.nvim_buf_get_name(e.buf)) == 1 then
        vim.bo[e.buf].buflisted = false
      end
    end)
  end,
})

local BigFileGroup = vim.api.nvim_create_augroup("ConfigBigFile", { clear = true })
vim.api.nvim_create_autocmd("BufReadPre", {
  group = BigFileGroup,
  pattern = "*",
  callback = function(e)
    local ok, size = pcall(vim.fn.getfsize, e.match)
    if ok and size > 1024 * 1024 then
      vim.b[e.buf].bigfile = true
    end
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = BigFileGroup,
  pattern = "*",
  callback = function(e)
    if vim.b[e.buf].bigfile then
      vim.opt_local.relativenumber = false
      vim.opt_local.syntax = "off"
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(e.buf) then
          vim.bo[e.buf].syntax = "off"
        end
      end)
    end
  end,
})

local PrimeagenGroup = vim.api.nvim_create_augroup("ThePrimeagen", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = PrimeagenGroup,
  pattern = "*",
  callback = function(e)
    if vim.b[e.buf].bigfile then
      return
    end
    if vim.bo[e.buf].buftype ~= "" then
      return
    end
    vim.cmd([[silent! keeppatterns keepjumps %s/\s\+$//e]])
  end,
})
