-- Treesitter: parsers + highlighting. Loaded eagerly because upstream does not
-- support lazy-loading; highlighting itself still starts per FileType.
-- "json" also covers jsonc (bun.lock, tsconfig*.json); jsdoc is an injection in
-- the javascript/ecma queries, so it belongs to the JS set.
local parsers = {
  "c", "cpp", "cmake", "make", "ruby", "yaml", "json", "bash", "regex", "sql",
  "javascript", "typescript", "tsx", "jsdoc",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    -- Upstream nvim-treesitter: "This plugin does not support lazy-loading."
    -- Load at startup so its parser installer and query symlinks are set up
    -- before any buffer needs highlighting.
    eager = true,
    build = function(path)
      -- Build runs before the plugin is loaded, so put it on the rtp first.
      vim.opt.rtp:append(path)
      pcall(vim.cmd, "TSUpdate")
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("ConfigTreesitter", { clear = true })
      local function start(buf)
        if vim.bo[buf].buftype ~= "" then return end
        if vim.b[buf].bigfile then return end -- syntax already off; skip parse cost
        -- Eager load means this can run during startup, before the command-line
        -- file's FileType fires. vim.treesitter.start() loads an unloaded named
        -- buffer with :edit, which reads the file before filetype detection is
        -- wired up, leaving 'filetype' empty (no LSP, no formatting). Wait for
        -- the FileType autocmd to supply a filetype.
        if vim.bo[buf].filetype == "" then return end
        -- pcall: no parser for this filetype is normal, not an error.
        pcall(vim.treesitter.start, buf)
      end
      -- FileType only (not BufEnter+FileType): starting twice per buffer is
      -- wasted work. Setting 'filetype' is what triggers highlighting.
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(e) start(e.buf) end,
      })
      -- Covers the buffer already on screen if this runs after its FileType
      -- fired (e.g. loaded later via :packadd). During eager startup the
      -- current buffer has no filetype yet, so start() bails and the FileType
      -- autocmd above handles it.
      start(vim.api.nvim_get_current_buf())

      -- Install parsers once the UI is up, or immediately if the plugin was
      -- pulled in after startup (e.g. a code file opened later).
      local function ensure_parsers() require("nvim-treesitter").install(parsers) end
      if vim.v.vim_did_init == 1 then
        ensure_parsers()
      else
        vim.api.nvim_create_autocmd("User", {
          group = group,
          pattern = "VeryLazy",
          once = true,
          callback = ensure_parsers,
        })
      end
    end,
  },
}
