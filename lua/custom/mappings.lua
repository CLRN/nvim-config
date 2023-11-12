---@type MappingsTable
local M = {}

-- M.general = {
--   n = {
--     [";"] = { ":", "enter command mode", opts = { nowait = true } },
--   },
--   v = {
--     [">"] = { ">gv", "indent"},
--   },
-- }
M.dap = {
  plugin = true,
  v = {
    ["<leader>de"] = {"<cmd> lua require('dapui').eval() <CR>"},
  },
  n = {
    ["<leader>db"] = {"<cmd> DapToggleBreakpoint <CR>"},
    ["<leader>du"] = {"<cmd> lua require('dapui').toggle() <CR>"},
    ["<leader>df"] = {"<cmd> lua require('dapui').float_element('scopes') <CR>"},
    ["<leader>de"] = {"<cmd> lua require('dapui').eval() <CR>"},
    ["<F6>"] = {"<cmd> DapToggleBreakpoint <CR>"},
    ["<F8>"] = {"<cmd> DapStepOver <CR>"},
    ["<F7>"] = {"<cmd> DapStepInto <CR>"},
    ["<F9>"] = {"<cmd> DapContinue <CR>"},
    ["<F4>"] = {"<cmd> DapTerminate <CR>"},
  }
}

M.dap_python = {
  plugin = true,
  n = {
    ["<leader>dpr"] = {
      function()
        require('dap-python').test_method()
      end
    }
  }
}
-- more keybinds!

return M
