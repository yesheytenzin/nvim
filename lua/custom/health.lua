--[[
  Health check for this configuration: :checkhealth custom
  Reports the Neovim version and the external tools the config relies on.
--]]

local function check_version()
  local verstr = tostring(vim.version())
  if not vim.version.ge then
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
    return
  end

  if vim.version.ge(vim.version(), "0.12") then
    vim.health.ok(string.format("Neovim version is: '%s'", verstr))
  else
    vim.health.error(string.format("Neovim out of date: '%s'. Upgrade to latest stable or nightly", verstr))
  end
end

-- Tools the config cannot start without.
local required = { "git", "make", "rg", "fd", "fzf" }

-- Tools only some languages need. A missing one is a hint, not a failure:
-- clangd is for C/C++, mise runs the Ruby LSP, zls is for Zig.
local optional = { "clangd", "mise", "zls" }

local function check_external_reqs()
  for _, exe in ipairs(required) do
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.error(string.format("Could not find executable: '%s'", exe))
    end
  end

  for _, exe in ipairs(optional) do
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end
end

return {
  check = function()
    vim.health.start("nvim configuration")

    vim.health.info([[NOTE: Not every warning is a 'must-fix' in `:checkhealth`

  Fix only warnings for plugins and languages you intend to use.
    Mason will give warnings for languages that are not installed.
    You do not need to install, unless you want to use those languages!]])

    local uv = vim.uv or vim.loop
    vim.health.info("System Information: " .. vim.inspect(uv.os_uname()))

    check_version()
    check_external_reqs()
  end,
}
