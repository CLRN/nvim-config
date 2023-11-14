---@type MappingsTable
local M = {}

M.general = {
  t = {
    ["<C-x>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
    ["<A-1>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:1tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-2>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:2tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-3>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:3tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-4>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:4tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-5>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:5tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-6>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:6tabnext<CR>", true, true, true), "Escape and go to tab" },

    -- switch between windows
    ["<C-j>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>h", true, true, true), "Escape and go to tab" },
    ["<C-'>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>l", true, true, true), "Escape and go to tab" },
    ["<C-k>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>j", true, true, true), "Escape and go to tab" },
    ["<C-l>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>k", true, true, true), "Escape and go to tab" },
  },

  n = {
    -- terminal
    ["<leader>tn"] = {"<cmd> tabnew <CR>"},
    ["<leader>tt"] = {"<cmd> tabnew | terminal <CR>"},
    ["<leader>tx"] = {"<cmd> tabclose <CR>"},

    ["<leader>tc"] = {"<cmd> Telescope commands <CR>"},
    ["<leader>tk"] = {"<cmd> Telescope keymaps <CR>"},

    ["<A-1>"] = { "<cmd> 1tabnext<CR>", "Go to tab" },
    ["<A-2>"] = { "<cmd> 2tabnext<CR>", "Go to tab" },
    ["<A-3>"] = { "<cmd> 3tabnext<CR>", "Go to tab" },
    ["<A-4>"] = { "<cmd> 4tabnext<CR>", "Go to tab" },
    ["<A-5>"] = { "<cmd> 5tabnext<CR>", "Go to tab" },
    ["<A-6>"] = { "<cmd> 6tabnext<CR>", "Go to tab" },

    -- window resize
    ["="] = { "<cmd>vertical resize +5<cr>", "make the window biger vertically" },
    ["-"] = { "<cmd>vertical resize -5<cr>", "make the window smaller vertically" },
    ["+"] = { "<cmd>horizontal  resize +2<cr>", "make the window biger horizontally" },
    ["_"] = { "<cmd>horizontal  resize -2<cr>", "make the window smaller horizontally" },
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
    ["<leader>pp"] = {"<cmd> PyrightSetPythonPath venv/bin/python <CR>"},

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

M.cmake_tools = {
  plugin = false,
  n = {
    ["<leader>cb"] = {"<cmd> CMakeBuild <CR>"}, 
    ["<leader>cd"] = {"<cmd> CMakeDebug <CR>"}, 
    ["<leader>cr"] = {"<cmd> CMakeRun <CR>"}, 
    ["<leader>ctr"] = {"<cmd> CMakeSelectLaunchTarget <CR>"}, 
    ["<leader>ctb"] = {"<cmd> CMakeSelectBuildTarget <CR>"}, 
  }
}
-- more keybinds!

return M
