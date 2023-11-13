---@type MappingsTable
local M = {}

M.general = {
  t = {
    -- ["<esc><esc>"] = {"<C-\\><C-N>"}
  },
  n = {
    -- terminal
    ["<leader>t'"] = {"<cmd> tabnext <CR>"},
    ["<leader>tj"] = {"<cmd> tabprevious <CR>"},
    ["<leader>tn"] = {"<cmd> tabnew <CR>"},
    ["<leader>tt"] = {"<cmd> tabnew | terminal <CR>"},
    ["<leader>tx"] = {"<cmd> tabclose <CR>"},

    -- tabs
    ["<leader>1"] = {"<cmd> 1tabnext <CR>"},
    ["<leader>2"] = {"<cmd> 2tabnext <CR>"},
    ["<leader>3"] = {"<cmd> 3tabnext <CR>"},
    ["<leader>4"] = {"<cmd> 4tabnext <CR>"},
    ["<leader>5"] = {"<cmd> 5tabnext <CR>"},
    ["<leader>6"] = {"<cmd> 6tabnext <CR>"},

    -- python
  },
  -- v = {
  --   [">"] = { ">gv", "indent"},
  -- },
}

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

    ["<leader>pi"] = {"<cmd> PyrightOrganizeImports <CR>"},

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
