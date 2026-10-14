-- Headless verification of the vim.pack config. Run via scripts/verify.sh.
-- Exits non-zero (cquit 1) if any check fails.
local pack = require("pack")

local results = {}
local function check(label, cond)
  results[#results + 1] = { label = label, ok = cond and true or false }
end

-- Lazy at startup: these must not be loaded before their trigger fires.
for _, mod in ipairs({ "blink.cmp", "fzf-lua", "trouble", "harpoon" }) do
  check(mod .. " not loaded at startup", package.loaded[mod] == nil)
end

-- Event trigger.
vim.cmd("doautocmd InsertEnter")
vim.wait(80)
check("InsertEnter -> blink.cmp", package.loaded["blink.cmp"] ~= nil)
check("blink LSP capabilities", type(require("blink.cmp").get_lsp_capabilities()) == "table")

-- Filetype trigger (assigning 'filetype' fires FileType).
vim.cmd("enew")
vim.bo.filetype = "lua"
vim.wait(80)
check("ft lua -> lspconfig chain (blink loaded)", package.loaded["blink.cmp"] ~= nil)
check("retired: cmp_nvim_lsp absent", package.loaded["cmp_nvim_lsp"] == nil)
check("retired: diffview absent", package.loaded["diffview"] == nil)
check("retired: other-nvim absent", package.loaded["other-nvim"] == nil)
check("retired: telescope absent", package.loaded["telescope"] == nil)

-- Smoke-load every declared spec; capture notifications for errors.
local notes = {}
local orig = vim.notify
vim.notify = function(msg, level)
  notes[#notes + 1] = ("[%s] %s"):format(level or 0, tostring(msg))
end
for _, name in ipairs(pack.list()) do
  pack.load(name)
end
vim.notify = orig
check("all config() load cleanly", #notes == 0)

-- Treesitter parsers AND queries must resolve. Queries are symlinked into
-- stdpath('data')/site/queries; broken links silently kill all highlighting
-- (treesitter disables vim syntax, so there is no fallback).
check("treesitter ruby query available", #vim.treesitter.query.get_files("ruby", "highlights") > 0)
check("treesitter cpp query available", #vim.treesitter.query.get_files("cpp", "highlights") > 0)
-- JS/TS set: javascript/typescript/tsx parsers plus their ecma/jsx query
-- dependencies (jsdoc is injected from ecma's injections.scm).
check("treesitter javascript query available", #vim.treesitter.query.get_files("javascript", "highlights") > 0)
check("treesitter typescript query available", #vim.treesitter.query.get_files("typescript", "highlights") > 0)
check("treesitter tsx query available", #vim.treesitter.query.get_files("tsx", "highlights") > 0)
-- Rust set: rust + toml (Cargo.toml/Cargo.lock) + comment (the parser rust
-- injects its comment nodes into).
check("treesitter rust query available", #vim.treesitter.query.get_files("rust", "highlights") > 0)
check("treesitter toml query available", #vim.treesitter.query.get_files("toml", "highlights") > 0)
check("treesitter comment query available", #vim.treesitter.query.get_files("comment", "highlights") > 0)

-- Offline cache: every wanted parser must have a compiled .so under
-- stdpath('data')/site/parser, otherwise the next boot downloads + compiles
-- it (see scripts/bootstrap.lua for the prefetch).
for _, lang in ipairs(require("treesitter_parsers")) do
  local so = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser", lang .. ".so")
  check("treesitter parser cached: " .. lang, vim.fn.filereadable(so) == 1)
end

-- LSP servers + tools must resolve without downloading. Mason's bin/ is
-- prepended to PATH by mason.nvim's setup (run above via pack.load); zls is
-- manual-or-system. Wanted sets owned by lua/lsp_manifest.lua.
for _, s in ipairs(require("lsp_manifest").servers) do
  check("lsp binary: " .. s.bin, vim.fn.executable(s.bin) == 1)
end
for _, tool in ipairs(require("lsp_manifest").tools) do
  check("tool binary: " .. tool, vim.fn.executable(tool) == 1)
end
local zls_manual = vim.fs.joinpath(vim.fn.stdpath("data"), "zls", "bin", "zls")
check("lsp binary: zls", vim.fn.executable(zls_manual) == 1 or vim.fn.executable("zls") == 1)

-- The fzf-lua functions referenced by our keymaps must all exist.
local fzf_ok, fzf_err = pcall(function()
  local f = require("fzf-lua")
  for _, m in ipairs({
    "files", "live_grep", "buffers", "helptags", "oldfiles",
    "lsp_document_symbols", "grep", "grep_cword", "grep_cWORD",
  }) do
    assert(type(f[m]) == "function", "fzf-lua." .. m .. " missing")
  end
end)
check("fzf-lua keymap API present" .. (fzf_ok and "" or (": " .. tostring(fzf_err))), fzf_ok)

-- In-buffer terminal (lua/terminal.lua, built-in :terminal, no plugin).
local term_ok, term = pcall(require, "terminal")
check("terminal module loads", term_ok and type(term.toggle) == "function")
check(
  "terminal toggle keymap <leader>ot",
  vim.fn.maparg("<leader>ot", "n") ~= ""
)

-- Toolchain manifests + status (lua/toolchain.lua, lua/lsp_manifest.lua).
local tc_ok, tc = pcall(require, "toolchain")
check("toolchain module loads", tc_ok and type(tc.show) == "function")
check("toolchain command :Toolchain", vim.fn.exists(":Toolchain") == 2)
check(
  "toolchain status keymap <leader>ci",
  vim.fn.maparg("<leader>ci", "n") ~= ""
)
local man_ok, man = pcall(require, "lsp_manifest")
check(
  "lsp_manifest servers+tools non-empty",
  man_ok and #man.servers > 0 and #man.tools > 0
)

local failed = 0
for _, r in ipairs(results) do
  if not r.ok then failed = failed + 1 end
  io.write((r.ok and "PASS " or "FAIL ") .. r.label .. "\n")
end
for _, n in ipairs(notes) do
  io.write("  " .. n .. "\n")
end
if failed > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
