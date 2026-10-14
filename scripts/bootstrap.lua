-- Headless prefetch of everything this config needs at runtime, so normal
-- boots never download: Treesitter parsers + Mason LSP servers/tools + zls.
-- Idempotent: anything already installed is skipped.
-- Usage: scripts/bootstrap.sh
--   (or directly: nvim --headless -c "luafile scripts/bootstrap.lua")
-- Exits non-zero (cquit 1) if anything fails to install.

local failures = {} --- @type string[]
local function log(msg)
  io.write(msg .. "\n")
end
local function fail(msg)
  failures[#failures + 1] = msg
  log("FAIL " .. msg)
end
local function ok(msg)
  log("ok   " .. msg)
end

-- init.lua already ran (pack specs registered, treesitter eager-loaded), but
-- pack.load is idempotent — ensure the pieces we drive are loaded.
local pack = require("pack")
pack.load("nvim-treesitter")

-- ── 1. Treesitter parsers ──────────────────────────────────────────────
do
  local wanted = require("treesitter_parsers")
  local tscfg = require("nvim-treesitter.config")
  local installed = tscfg.get_installed()
  local missing = vim.tbl_filter(function(p)
    return not vim.list_contains(installed, p)
  end, wanted)
  if #missing == 0 then
    ok("treesitter parsers (" .. #wanted .. "/" .. #wanted .. " cached)")
  else
    log("installing treesitter parsers: " .. table.concat(missing, ", "))
    local task = require("nvim-treesitter").install(missing, { summary = true })
    local done, err = task:pwait(15 * 60 * 1000)
    if not done then
      fail("treesitter install timed out: " .. tostring(err))
    else
      local still_missing = vim.tbl_filter(function(p)
        return not vim.list_contains(require("nvim-treesitter.config").get_installed(), p)
      end, wanted)
      if #still_missing > 0 then
        fail("treesitter parsers still missing: " .. table.concat(still_missing, ", "))
      else
        ok("treesitter parsers (" .. #wanted .. " installed)")
      end
    end
  end
end

-- ── 2. Mason LSP servers + tools ───────────────────────────────────────
do
  pack.load("mason.nvim")
  pack.load("mason-lspconfig.nvim")
  pack.load("mason-tool-installer.nvim")

  -- Tools owned by mason-tool-installer (run_on_start = false, so normal
  -- boots never fetch these — only this script and :MasonToolsInstall do).
  -- Sync variant blocks, which is what headless mode needs. Tool list owned
  -- by lua/lsp_manifest.lua.
  local tools = require("lsp_manifest").tools
  local ok_tools, err_tools = pcall(vim.cmd, "MasonToolsInstallSync")
  if not ok_tools then
    fail("MasonToolsInstallSync: " .. tostring(err_tools))
  else
    ok("mason tools (" .. table.concat(tools, ", ") .. ")")
  end

  -- LSP servers owned by mason-lspconfig. Its automatic ensure_installed is
  -- skipped in headless mode, so install the Mason packages explicitly here.
  -- (On normal boots the same ensure_installed covers fresh machines on
  -- first file-open instead.) Server list owned by lua/lsp_manifest.lua.
  -- Skips packages that are already installed, so repeat runs touch no network.
  local server_pkgs = vim.tbl_map(function(s)
    return s.mason
  end, require("lsp_manifest").servers)
  local mr_ok, mr = pcall(require, "mason-registry")
  if not mr_ok then
    fail("mason-registry unavailable")
  else
    mr.refresh(function()
      local missing = vim.tbl_filter(function(name)
        local po, pkg = pcall(mr.get_package, name)
        return not (po and pkg:is_installed())
      end, server_pkgs)
      if #missing == 0 then
        ok("mason LSP servers (" .. table.concat(server_pkgs, ", ") .. " cached)")
      else
        log("installing mason LSP servers: " .. table.concat(missing, ", "))
        local ok_mason, err_mason =
          pcall(vim.cmd, "MasonInstall " .. table.concat(missing, " "))
        if not ok_mason then
          fail("MasonInstall: " .. tostring(err_mason))
        else
          local waited = vim.wait(10 * 60 * 1000, function()
            for _, name in ipairs(missing) do
              local po, pkg = pcall(mr.get_package, name)
              if not po or not pkg:is_installed() then
                return false
              end
            end
            return true
          end)
          if waited then
            ok("mason LSP servers (" .. table.concat(missing, ", ") .. " installed)")
          else
            fail("mason LSP servers not installed after 10min: " .. table.concat(missing, ", "))
          end
        end
      end
      _G.__bootstrap_mason_done = true
    end)
    -- mr.refresh() with a callback is async: block until it (and any install
    -- above) finishes. The callback runs synchronously when the registry is
    -- already cached, so this returns immediately on warm machines.
    local refreshed = vim.wait(11 * 60 * 1000, function()
      return _G.__bootstrap_mason_done == true
    end)
    if not refreshed then
      fail("mason registry refresh timed out")
    end
    _G.__bootstrap_mason_done = nil
  end
end

-- ── 3. zls (not a Mason package) ───────────────────────────────────────
do
  local manual = vim.fs.joinpath(vim.fn.stdpath("data"), "zls", "bin", "zls")
  if vim.fn.executable(manual) == 1 then
    ok("zls (manual install at " .. manual .. ")")
  elseif vim.fn.executable("zls") == 1 then
    ok("zls (system: " .. vim.fn.exepath("zls") .. ")")
  else
    fail("zls missing: install to "
      .. manual
      .. " (see github.com/zigtools/zls releases) or provide a system zls (e.g. `mise use -g zls`)")
  end
end

-- ── Summary ────────────────────────────────────────────────────────────
if #failures > 0 then
  log(#failures .. " bootstrap step(s) failed")
  vim.cmd("cquit 1")
else
  log("Done. Future boots will not download parsers or LSP files.")
  vim.cmd("qa!")
end
