-- Toolchain manifests, made live: :Toolchain shows everything wanted vs
-- installed (parsers, servers, tools, zls), and saving either manifest file
-- installs what was just added — no restart, no :MasonToolsInstall.
-- Manifests: lua/treesitter_parsers.lua, lua/lsp_manifest.lua.
local M = {}

--- Re-require a manifest so save-handlers see the just-written content.
--- @param name string
local function fresh(name)
  package.loaded[name] = nil
  return require(name)
end

local group = vim.api.nvim_create_augroup("ConfigToolchain", { clear = true })

-- Added parser names install in the background; reopen buffers of that
-- filetype to start highlighting with them.
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "treesitter_parsers.lua",
  callback = function(e)
    if not e.match:match("lua/treesitter_parsers%.lua$") then
      return
    end
    local ts_ok, ts = pcall(require, "nvim-treesitter")
    if not ts_ok then
      return
    end
    local wanted = fresh("treesitter_parsers")
    local installed = require("nvim-treesitter.config").get_installed()
    local missing = vim.tbl_filter(function(p)
      return not vim.list_contains(installed, p)
    end, wanted)
    if #missing == 0 then
      vim.notify("Toolchain: parsers already complete", vim.log.levels.INFO)
    else
      ts.install(missing)
      vim.notify("Toolchain: installing parsers: " .. table.concat(missing, ", "), vim.log.levels.INFO)
    end
  end,
})

-- Added servers/tools install in the background via Mason. A new server only
-- attaches after reopen/restart (its lspconfig enable lives in coding.lua,
-- which runs once at load).
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "lsp_manifest.lua",
  callback = function(e)
    if not e.match:match("lua/lsp_manifest%.lua$") then
      return
    end
    require("pack").load("mason.nvim")
    local mr_ok, mr = pcall(require, "mason-registry")
    if not mr_ok then
      vim.notify("Toolchain: mason-registry unavailable", vim.log.levels.ERROR)
      return
    end
    local manifest = fresh("lsp_manifest")
    local pkgs = vim.tbl_map(function(s)
      return s.mason
    end, manifest.servers)
    vim.list_extend(pkgs, manifest.tools)
    local missing = vim.tbl_filter(function(name)
      local ok, pkg = pcall(mr.get_package, name)
      return not (ok and pkg:is_installed())
    end, pkgs)
    if #missing == 0 then
      vim.notify("Toolchain: servers + tools already complete", vim.log.levels.INFO)
    else
      vim.cmd("MasonInstall " .. table.concat(missing, " "))
      vim.notify(
        "Toolchain: installing " .. table.concat(missing, ", ") .. " — reopen files to attach new servers",
        vim.log.levels.INFO
      )
    end
  end,
})

--- One installed-version lookup, never errors.
local function installed_version(mr, name)
  local ok, pkg = pcall(mr.get_package, name)
  if ok and pkg:is_installed() then
    local vok, ver = pcall(function()
      return pkg:get_installed_version()
    end)
    if vok then
      return ver
    end
    return "installed"
  end
  return nil
end

--- :Toolchain status view: wanted vs installed for every manifest entry.
function M.show()
  require("pack").load("mason.nvim")
  local mr_ok, mr = pcall(require, "mason-registry")
  local lines = { "Toolchain — wanted vs installed", "" }

  lines[#lines + 1] = "Parsers (" .. #require("treesitter_parsers") .. ")"
  local ts_ok, tscfg = pcall(require, "nvim-treesitter.config")
  local installed = ts_ok and tscfg.get_installed() or {}
  for _, p in ipairs(require("treesitter_parsers")) do
    local has = vim.list_contains(installed, p)
    lines[#lines + 1] = ("  %s %s"):format(has and "✓" or "✗", p)
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Servers"
  for _, s in ipairs(require("lsp_manifest").servers) do
    local ver = mr_ok and installed_version(mr, s.mason) or nil
    local on_path = vim.fn.executable(s.bin) == 1
    local state = ver and ("✓ " .. ver) or (on_path and "✓ on PATH (not Mason)" or "✗ missing")
    lines[#lines + 1] = ("  %s %s (%s)"):format(state, s.lsp, s.mason)
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Tools"
  for _, tool in ipairs(require("lsp_manifest").tools) do
    local ver = mr_ok and installed_version(mr, tool) or nil
    lines[#lines + 1] = ("  %s %s"):format(ver and ("✓ " .. ver) or "✗ missing", tool)
  end

  lines[#lines + 1] = ""
  local manual = vim.fs.joinpath(vim.fn.stdpath("data"), "zls", "bin", "zls")
  local zls = vim.fn.executable(manual) == 1 and ("✓ manual (" .. manual .. ")")
    or vim.fn.executable("zls") == 1 and ("✓ system (" .. vim.fn.exepath("zls") .. ")")
    or "✗ missing"
  lines[#lines + 1] = "zls: " .. zls

  vim.cmd("belowright 20new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.opt_local.buftype = "nofile"
  vim.opt_local.bufhidden = "wipe"
  vim.opt_local.swapfile = false
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true, desc = "Close" })
end

vim.api.nvim_create_user_command("Toolchain", M.show, { desc = "Show wanted vs installed parsers/servers/tools" })
vim.keymap.set("n", "<leader>ci", M.show, { desc = "Toolchain status" })

return M
