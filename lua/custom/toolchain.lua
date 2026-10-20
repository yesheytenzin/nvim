-- Toolchain manifests, made live: :Toolchain shows everything wanted vs
-- installed (parsers, servers, tools, zls), and saving either manifest file
-- installs what was just added — no restart, no :MasonToolsInstall.
-- Manifests: lua/custom/parser_manifest.lua, lua/custom/lsp_manifest.lua.
local M = {}

--- Re-require a manifest so save-handlers see the just-written content.
--- @param name string
local function fresh(name)
  package.loaded[name] = nil
  return require(name)
end

local function is_manifest(path, name)
  local expected = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "custom", name)
  return vim.fs.normalize(path) == vim.fs.normalize(expected)
end

local group = vim.api.nvim_create_augroup("ConfigToolchain", { clear = true })

-- Added parser names install in the background; reopen buffers of that
-- filetype to start highlighting with them.
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "parser_manifest.lua",
  callback = function(e)
    if not is_manifest(e.match, "parser_manifest.lua") then
      return
    end
    local ts_ok, ts = pcall(require, "nvim-treesitter")
    if not ts_ok then
      return
    end
    local wanted = fresh("custom.parser_manifest")
    local missing = require("custom.manifest_util").ts_missing(wanted)
    if #missing == 0 then
      vim.notify("Toolchain: parsers already complete", vim.log.levels.INFO)
    else
      ts.install(missing)
      vim.notify("Toolchain: installing parsers: " .. table.concat(missing, ", "), vim.log.levels.INFO)
    end
  end,
})

-- Added servers/tools install in the background via Mason. A new server only
-- attaches after reopen/restart (its lspconfig enable lives in lsp.lua,
-- which runs once at load).
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "lsp_manifest.lua",
  callback = function(e)
    if not is_manifest(e.match, "lsp_manifest.lua") then
      return
    end
    if not require("custom.pack").load("mason.nvim") then
      return
    end
    local mr_ok, mr = pcall(require, "mason-registry")
    if not mr_ok then
      vim.notify("Toolchain: mason-registry unavailable", vim.log.levels.ERROR)
      return
    end
    local manifest = fresh("custom.lsp_manifest")
    local pkgs = vim.tbl_map(function(s)
      return s.mason
    end, manifest.servers)
    vim.list_extend(
      pkgs,
      vim.tbl_map(function(t)
        return t.name
      end, manifest.tools)
    )
    -- Presence-only on save: no surprise downgrades from an edit. Version
    -- drift is flagged by :Toolchain and fixed by scripts/bootstrap.sh.
    local missing = require("custom.manifest_util").mason_missing(mr, pkgs)
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

--- :Toolchain status view: wanted vs installed for every manifest entry.
--- Version drift (installed ≠ pin) and Mason packages outside the manifest
--- are flagged so `MasonToolsClean` candidates are visible, never auto-removed.
function M.show()
  require("custom.pack").load("mason.nvim")
  local mr_ok, mr = pcall(require, "mason-registry")
  local util = require("custom.manifest_util")
  local manifest = require("custom.lsp_manifest")
  local lines = { "Toolchain — wanted vs installed", "" }

  lines[#lines + 1] = "Parsers (" .. #require("custom.parser_manifest") .. ")"
  local ts_ok, tscfg = pcall(require, "nvim-treesitter.config")
  local installed = ts_ok and tscfg.get_installed() or {}
  for _, p in ipairs(require("custom.parser_manifest")) do
    local has = vim.list_contains(installed, p)
    lines[#lines + 1] = ("  %s %s"):format(has and "✓" or "✗", p)
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Servers"
  for _, s in ipairs(manifest.servers) do
    local ver = mr_ok and util.installed_version(mr, s.mason) or nil
    local want = s.version and ("want " .. s.version) or "unpinned"
    local state = ver == nil and "✗ missing"
      or ver ~= s.version and ("≠ " .. ver .. " (" .. want .. ") — run bootstrap.sh")
      or ("✓ " .. ver)
    if ver == nil and vim.fn.executable(s.bin) == 1 then
      state = "✓ on PATH (not Mason)"
    end
    lines[#lines + 1] = ("  %s %s (%s)"):format(state, s.lsp, s.mason)
  end

  -- Ruby gems owned by mise: one copy per Ruby, at the pinned version. A
  -- Ruby whose copy is missing or stale breaks the LSP for projects pinned
  -- to it, so the rubies that need attention are named.
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Gems (mise — one copy per Ruby)"
  for _, g in ipairs(manifest.gems or {}) do
    local states = {}
    for _, r in ipairs(util.mise_rubies()) do
      local v = util.gem_version(r.version, g.name)
      local mark = v == g.version and "✓" or (v and ("≠ " .. v) or "✗")
      states[#states + 1] = ("%s %s"):format(r.version, mark)
    end
    lines[#lines + 1] = ("  %s (%s): %s"):format(g.name, g.version, table.concat(states, "  "))
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Tools"
  for _, tool in ipairs(manifest.tools) do
    local ver = mr_ok and util.installed_version(mr, tool.name) or nil
    local state = ver == nil and "✗ missing"
      or ver ~= tool.version and ("≠ " .. ver .. " (want " .. tool.version .. ") — run bootstrap.sh")
      or ("✓ " .. ver)
    lines[#lines + 1] = ("  %s %s"):format(state, tool.name)
  end

  lines[#lines + 1] = ""
  local manual = vim.fs.joinpath(vim.fn.stdpath("data"), "zls", "bin", "zls")
  local zls_bin = vim.fn.executable(manual) == 1 and manual
    or vim.fn.executable("zls") == 1 and vim.fn.exepath("zls")
    or nil
  local zls_state = "✗ missing"
  if zls_bin then
    local out = vim.trim(vim.fn.system({ zls_bin, "--version" }))
    local pin = manifest.zls.version
    zls_state = (not pin or out:find(pin, 1, true)) and ("✓ " .. out .. " (" .. zls_bin .. ")")
      or ("≠ " .. out .. " (want " .. pin .. ")")
  end
  lines[#lines + 1] = "zls: " .. zls_state

  -- Installed Mason packages that no manifest owns: review candidates for
  -- :MasonToolsClean. Listed only — never removed automatically.
  if mr_ok then
    local owned = {}
    for _, s in ipairs(manifest.servers) do
      owned[s.mason] = true
    end
    for _, t in ipairs(manifest.tools) do
      owned[t.name] = true
    end
    local extra = {}
    for _, pkg in ipairs(mr.get_installed_packages()) do
      if not owned[pkg.name] then
        extra[#extra + 1] = pkg.name
      end
    end
    if #extra > 0 then
      table.sort(extra)
      lines[#lines + 1] = ""
      lines[#lines + 1] = "Mason packages outside the manifest (" .. #extra .. ")"
      for _, name in ipairs(extra) do
        lines[#lines + 1] = "  ? " .. name
      end
    end
  end

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
