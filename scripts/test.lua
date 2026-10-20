local config = vim.fn.getcwd()
package.path = table.concat({
  config .. "/lua/?.lua",
  config .. "/lua/?/init.lua",
  package.path,
}, ";")

local failures = 0

local function check(label, condition)
  if condition then
    io.write("PASS " .. label .. "\n")
    return
  end
  failures = failures + 1
  io.write("FAIL " .. label .. "\n")
end

local original_pack_add = vim.pack.add
local original_packadd = vim.cmd.packadd
local original_notify = vim.notify

local function load_pack(specs)
  package.loaded["custom.pack"] = nil
  vim.pack.add = function() end
  vim.cmd.packadd = function() end
  vim.notify = function() end
  local pack = require("custom.pack")
  pack.setup(specs)
  return pack
end

do
  local order = {}
  local pack = load_pack({
    {
      "test/dep",
      config = function()
        order[#order + 1] = "dep"
      end,
    },
    {
      "test/owner",
      deps = { "dep" },
      config = function()
        order[#order + 1] = "owner"
      end,
    },
  })
  check("loader dependency order", pack.load("owner") and table.concat(order, ",") == "dep,owner")
  check("loader success is idempotent", pack.load("owner") and table.concat(order, ",") == "dep,owner")
end

do
  local configured = false
  local pack = load_pack({
    {
      "test/owner",
      deps = { "missing" },
      config = function()
        configured = true
      end,
    },
  })
  check("loader rejects a missing dependency", not pack.load("owner") and not configured)
end

do
  local configured = false
  local pack = load_pack({
    {
      "test/a",
      deps = { "b" },
      config = function()
        configured = true
      end,
    },
    {
      "test/b",
      deps = { "a" },
      config = function()
        configured = true
      end,
    },
  })
  check("loader rejects dependency cycles", not pack.load("a") and not configured)
end

do
  local runs = 0
  local pack
  pack = load_pack({
    {
      "test/a",
      config = function()
        pack.load("b")
      end,
    },
    {
      "test/b",
      config = function()
        runs = runs + 1
      end,
    },
    { "test/root", deps = { "a", "b" } },
  })
  check("loader skips dependencies loaded during config", pack.load("root") and runs == 1)
end

do
  local attempts = 0
  local pack = load_pack({
    {
      "test/broken",
      config = function()
        attempts = attempts + 1
        error("broken config")
      end,
    },
  })
  check("loader reports config failure", not pack.load("broken"))
  check("loader does not replay partial config", not pack.load("broken") and attempts == 1)
end

do
  local builds = 0
  local specs = {
    {
      "test/buildable",
      build = function()
        builds = builds + 1
      end,
    },
  }
  local pack = load_pack(specs)
  pack.setup(specs)
  vim.api.nvim_exec_autocmds("PackChanged", {
    data = { kind = "update", path = "/tmp/buildable", spec = { name = "buildable" } },
  })
  check("PackChanged build hook is not duplicated", builds == 1)
end

vim.pack.add = original_pack_add
vim.cmd.packadd = original_packadd
vim.notify = original_notify

do
  package.loaded["custom.toolchain"] = nil
  package.loaded["custom.parser_manifest"] = nil
  package.loaded["custom.lsp_manifest"] = nil

  local parser_installs = {}
  local mason_installs = {}
  package.preload["nvim-treesitter"] = function()
    return {
      install = function(names)
        parser_installs = names
      end,
    }
  end
  package.preload["mason-registry"] = function()
    return {}
  end

  local original_pack = package.loaded["custom.pack"]
  local original_util = package.loaded["custom.manifest_util"]
  package.loaded["custom.pack"] = {
    load = function()
      return true
    end,
  }
  package.loaded["custom.manifest_util"] = {
    ts_missing = function()
      return { "lua" }
    end,
    mason_missing = function()
      return { "lua-language-server" }
    end,
  }

  vim.api.nvim_create_user_command("MasonInstall", function(opts)
    mason_installs[#mason_installs + 1] = opts.args
  end, { nargs = "*" })
  require("custom.toolchain")
  vim.api.nvim_exec_autocmds("BufWritePost", {
    pattern = config .. "/lua/custom/parser_manifest.lua",
  })
  vim.api.nvim_exec_autocmds("BufWritePost", {
    pattern = config .. "/lua/custom/lsp_manifest.lua",
  })

  check("parser manifest save installs missing parsers", vim.deep_equal(parser_installs, { "lua" }))
  check("LSP manifest save installs missing packages", mason_installs[1] == "lua-language-server")

  package.loaded["custom.pack"] = original_pack
  package.loaded["custom.manifest_util"] = original_util
  package.preload["nvim-treesitter"] = nil
  package.preload["mason-registry"] = nil
  vim.api.nvim_del_user_command("MasonInstall")
end

do
  local blink_config
  package.loaded["blink.cmp"] = {
    setup = function(config)
      blink_config = config
    end,
  }
  for _, spec in ipairs(require("custom.plugins.completion")) do
    if spec[1] == "saghen/blink.cmp" then
      spec.config()
    end
  end
  check("Blink gives LSP a modest source bonus", blink_config.sources.providers.lsp.score_offset == 4)
  package.loaded["blink.cmp"] = nil
end

do
  package.loaded["custom.terminal"] = nil
  local original_jobstart = vim.fn.jobstart
  local argv
  vim.fn.jobstart = function(command)
    argv = command
    return 1
  end
  local terminal = require("custom.terminal")
  terminal.toggle()
  check("terminal starts the shell as argv", type(argv) == "table" and #argv == 1)
  terminal.toggle()
  vim.fn.jobstart = original_jobstart
end

do
  package.loaded["custom.terminal"] = nil
  local shell = vim.env.SHELL
  local windows = #vim.api.nvim_list_wins()
  vim.env.SHELL = "/nonexistent/review-shell"
  local ok = pcall(require("custom.terminal").toggle)
  check("terminal handles spawn errors", ok and #vim.api.nvim_list_wins() == windows)
  vim.env.SHELL = shell
end

if failures > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
