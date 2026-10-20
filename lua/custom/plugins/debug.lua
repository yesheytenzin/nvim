local function dap_call(method)
  return function()
    require("dap")[method]()
  end
end

local function conditional_breakpoint()
  vim.ui.input({ prompt = "Break when: " }, function(condition)
    if condition and condition ~= "" then
      require("dap").set_breakpoint(condition)
    end
  end)
end

local function start_or_continue()
  local dap = require("dap")
  if dap.session() or vim.bo.filetype ~= "ruby" then
    return dap.continue()
  end
  local wanted = vim.fn.expand("%:t"):match("_spec%.rb$") and "run rspec current file" or "debug current file"
  for _, config in ipairs(dap.configurations.ruby or {}) do
    if config.name == wanted then
      return dap.run(config)
    end
  end
  dap.continue()
end

return {
  { "nvim-neotest/nvim-nio" },
  { "rcarriga/nvim-dap-ui" },
  { "suketa/nvim-dap-ruby" },
  {
    "mfussenegger/nvim-dap",
    deps = { "nvim-nio", "nvim-dap-ui", "nvim-dap-ruby" },
    keys = {
      { "<F5>", start_or_continue, desc = "Debug: start / continue" },
      { "<F10>", dap_call("step_over"), desc = "Debug: step over" },
      { "<F11>", dap_call("step_into"), desc = "Debug: step into" },
      { "<F12>", dap_call("step_out"), desc = "Debug: step out" },
      { "<S-F5>", dap_call("terminate"), desc = "Debug: stop" },
      { "<F17>", dap_call("terminate"), desc = "Debug: stop (Shift-F5 in some terminals)" },
      { "<F9>", dap_call("toggle_breakpoint"), desc = "Debug: toggle breakpoint" },
      { "<S-F9>", conditional_breakpoint, desc = "Debug: conditional breakpoint" },
      { "<F21>", conditional_breakpoint, desc = "Debug: conditional breakpoint (Shift-F9 in some terminals)" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      require("dap-ruby").setup()
      dapui.setup()
      dap.listeners.after.event_initialized.dapui = dapui.open
      dap.listeners.before.event_terminated.dapui = dapui.close
      dap.listeners.before.event_exited.dapui = dapui.close

      local past_entry = {}
      dap.listeners.after.event_stopped.skip_ruby_entry = function(session, body)
        if session.config.type ~= "ruby" or past_entry[session.id] then
          return
        end
        past_entry[session.id] = true
        if body.reason == "pause" then
          session:request("continue", { threadId = body.threadId })
        end
      end
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
    end,
  },
}
