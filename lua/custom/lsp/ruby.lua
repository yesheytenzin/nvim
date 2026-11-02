local M = {}

function M.command(dispatchers, config)
  -- Prefer direct `ruby-lsp` (mise shim resolves per-project Ruby).
  -- Old `mise exec -- ruby -S ruby-lsp` broke: `ruby -S` finds the mise
  -- shim (an ELF binary) and tries to parse it as Ruby -> SyntaxError
  -- `Invalid char '\x7F'` -> exit 1 -> "Client ruby_lsp quit" prompt.
  -- It also failed when current Ruby (e.g. 4.0.9) has no ruby-lsp gem.
  local cmd
  if vim.fn.executable("ruby-lsp") == 1 then
    cmd = { "ruby-lsp" }
  elseif vim.fn.executable("mise") == 1 then
    -- Let mise resolve the tool in the project cwd, no `ruby -S` indirection.
    cmd = { "mise", "exec", "--", "ruby-lsp" }
  else
    cmd = { "ruby-lsp" }
  end
  return vim.lsp.rpc.start(cmd, dispatchers, { cwd = config.cmd_cwd or config.root_dir })
end

-- Removed: sequence_completion barrier (documentHighlight before every
-- completion). It added a full server roundtrip to every keystroke and hung
-- completions entirely while ruby-lsp was indexing (e.g. right after reopen).
-- Kept as no-op for backward compatibility with old configs.
function M.sequence_completion(_)
  return nil
end

-- Removed: fake didOpen + documentSymbol refresh spam. Neovim's built-in
-- incremental sync already keeps ruby-lsp up to date; the extra notifies
-- raced version tracking and made the index go stale/slow.
-- Kept as no-op for backward compatibility.
function M.setup_refresh()
  return nil
end

return M
