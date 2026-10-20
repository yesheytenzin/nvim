local failures = {}
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

local pack = require("custom.pack")
pack.load("nvim-treesitter")

do
  local wanted = require("custom.parser_manifest")
  local missing = require("custom.manifest_util").ts_missing(wanted)
  if #missing == 0 then
    ok("treesitter parsers (" .. #wanted .. "/" .. #wanted .. " cached)")
  else
    log("installing treesitter parsers: " .. table.concat(missing, ", "))
    local task = require("nvim-treesitter").install(missing, { summary = true })
    local done, err = task:pwait(15 * 60 * 1000)
    if not done then
      fail("treesitter install timed out: " .. tostring(err))
    else
      local still_missing = require("custom.manifest_util").ts_missing(wanted)
      if #still_missing > 0 then
        fail("treesitter parsers still missing: " .. table.concat(still_missing, ", "))
      else
        ok("treesitter parsers (" .. #wanted .. " installed)")
      end
    end
  end
end

do
  pack.load("mason.nvim")
  pack.load("mason-lspconfig.nvim")
  pack.load("mason-tool-installer.nvim")

  local tools = require("custom.lsp_manifest").tools
  local tool_names = vim.tbl_map(function(t)
    return t.name
  end, tools)
  local ok_tools, err_tools = pcall(vim.cmd, "MasonToolsInstallSync")
  if not ok_tools then
    fail("MasonToolsInstallSync: " .. tostring(err_tools))
  else
    ok("mason tools (" .. table.concat(tool_names, ", ") .. ")")
  end

  local servers = require("custom.lsp_manifest").servers
  local mr_ok, mr = pcall(require, "mason-registry")
  if not mr_ok then
    fail("mason-registry unavailable")
  else
    local state = { done = false }
    mr.refresh(function()
      local util = require("custom.manifest_util")
      local missing = util.mason_drift(mr, servers)
      if #missing == 0 then
        local names = vim.tbl_map(function(s)
          return s.mason
        end, servers)
        ok("mason LSP servers (" .. table.concat(names, ", ") .. " cached)")
      else
        log("installing mason LSP servers: " .. table.concat(missing, ", "))
        local ok_mason, err_mason = pcall(vim.cmd, "MasonInstall " .. table.concat(missing, " "))
        if not ok_mason then
          fail("MasonInstall: " .. tostring(err_mason))
        else
          local names = vim.tbl_map(function(s)
            return s.mason
          end, servers)
          local waited = vim.wait(10 * 60 * 1000, function()
            return #util.mason_missing(mr, names) == 0
          end)
          if waited then
            ok("mason LSP servers (" .. table.concat(missing, ", ") .. " installed)")
          else
            fail("mason LSP servers not installed after 10min: " .. table.concat(missing, ", "))
          end
        end
      end
      state.done = true
    end)
    if not vim.wait(11 * 60 * 1000, function()
      return state.done
    end) then
      fail("mason registry refresh timed out")
    end
  end
end

do
  local gems = require("custom.lsp_manifest").gems
  local util = require("custom.manifest_util")
  local rubies = util.mise_rubies()
  if #rubies == 0 then
    fail("mise reports no installed rubies")
  end
  for _, g in ipairs(gems) do
    local missing = util.gem_drift(g.name, g.version)
    if #missing == 0 then
      ok(("gem %s (%s) in %d ruby(s)"):format(g.name, g.version, #rubies))
    else
      log(("installing gem %s %s into ruby %s"):format(g.name, g.version, table.concat(missing, ", ")))
      local failed = {}
      for _, v in ipairs(missing) do
        local cmd = { "mise", "x", "ruby@" .. v, "--", "gem", "install", g.name, "-v", g.version, "--no-document" }
        vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
          failed[#failed + 1] = v
        end
      end
      if #failed > 0 then
        fail(("gem %s %s failed for ruby %s"):format(g.name, g.version, table.concat(failed, ", ")))
      else
        ok(("gem %s (%s) installed into %d ruby(s)"):format(g.name, g.version, #missing))
      end
    end
  end
end

do
  local pin = require("custom.lsp_manifest").zls.version
  local manual = vim.fs.joinpath(vim.fn.stdpath("data"), "zls", "bin", "zls")
  local bin = vim.fn.executable(manual) == 1 and manual
    or vim.fn.executable("zls") == 1 and vim.fn.exepath("zls")
    or nil
  if not bin then
    fail(
      "zls missing: install to "
        .. manual
        .. " (see github.com/zigtools/zls releases) or provide a system zls (e.g. `mise use -g zls`)"
    )
  else
    local out = vim.fn.system({ bin, "--version" })
    if pin and not out:find(pin, 1, true) then
      fail(("zls version drift: want %s, got %s"):format(pin, vim.trim(out)))
    else
      ok("zls (" .. bin .. (pin and (" @ " .. vim.trim(out)) or "") .. ")")
    end
  end
end

if #failures > 0 then
  log(#failures .. " bootstrap step(s) failed")
  vim.cmd("cquit 1")
else
  log("Done. Future boots will not download parsers or LSP files.")
  vim.cmd("qa!")
end
