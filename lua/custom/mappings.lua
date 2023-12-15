---@type MappingsTable
local M = {}

M.general = {
  t = {
    ["<C-x>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },

    -- tabs
    ["<A-1>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:1tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-2>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:2tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-3>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:3tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-4>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:4tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-5>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:5tabnext<CR>", true, true, true), "Escape and go to tab" },
    ["<A-6>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:6tabnext<CR>", true, true, true), "Escape and go to tab" },

    -- switch between windows
    ["<C-j>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>h", true, true, true), "Escape and go to window" },
    ["<C-'>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>l", true, true, true), "Escape and go to window" },
    ["<C-k>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>j", true, true, true), "Escape and go to window" },
    ["<C-l>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>k", true, true, true), "Escape and go to window" },

    -- harpoon
    ["<A-y>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').toggle_quick_menu() <cr>", true, true, true), "Escape and go to harpoon" },

    ["<A-j>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(1) <cr>", true, true, true), "Escape and go to harpoon" },
    ["<A-k>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(2) <cr>", true, true, true), "Escape and go to harpoon" },
    ["<A-l>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(3) <cr>", true, true, true), "Escape and go to harpoon" },
    ["<A-'>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(4) <cr>", true, true, true), "Escape and go to harpoon" },

    ["<A-u>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(1) <cr>", true, true, true), "Escape and go to harpoon term" },
    ["<A-i>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(2) <cr>", true, true, true), "Escape and go to harpoon term" },
    ["<A-o>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(3) <cr>", true, true, true), "Escape and go to harpoon term" },
    ["<A-p>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(4) <cr>", true, true, true), "Escape and go to harpoon term" },
  },

  n = {
    -- terminal
    ["<leader>tn"] = {"<cmd> tabnew <CR>"},
    ["<leader>tt"] = {"<cmd> tabnew | terminal <CR>"},
    ["<leader>tx"] = {"<cmd> tabclose <CR>"},

    ["<leader>sc"] = {"<cmd> Telescope commands <CR>"},
    ["<leader>sk"] = {"<cmd> Telescope keymaps <CR>"},
    ["<leader>sh"] = {"<cmd> Telescope command_history <CR>"},

    ["<A-1>"] = { "<cmd> 1tabnext<CR>", "Go to tab" },
    ["<A-2>"] = { "<cmd> 2tabnext<CR>", "Go to tab" },
    ["<A-3>"] = { "<cmd> 3tabnext<CR>", "Go to tab" },
    ["<A-4>"] = { "<cmd> 4tabnext<CR>", "Go to tab" },
    ["<A-5>"] = { "<cmd> 5tabnext<CR>", "Go to tab" },
    ["<A-6>"] = { "<cmd> 6tabnext<CR>", "Go to tab" },

    -- window resize
    ["<A-=>"] = { "<cmd>vertical resize +5<cr>", "make the window biger vertically" },
    ["<A-->"] = { "<cmd>vertical resize -5<cr>", "make the window smaller vertically" },
    ["<A-+>"] = { "<cmd>horizontal  resize +2<cr>", "make the window biger horizontally" },
    ["<A-_>"] = { "<cmd>horizontal  resize -2<cr>", "make the window smaller horizontally" },

    -- harpoon
    ["<A-h>"] = { "<cmd> lua require('harpoon.mark').add_file() <cr>" },
    ["<A-y>"] = { "<cmd> lua require('harpoon.ui').toggle_quick_menu() <cr>" },

    ["<A-j>"] = { "<cmd> lua require('harpoon.ui').nav_file(1) <cr>" },
    ["<A-k>"] = { "<cmd> lua require('harpoon.ui').nav_file(2) <cr>" },
    ["<A-l>"] = { "<cmd> lua require('harpoon.ui').nav_file(3) <cr>" },
    ["<A-'>"] = { "<cmd> lua require('harpoon.ui').nav_file(4) <cr>" },

    ["<A-u>"] = { "<cmd> lua require('harpoon.term').gotoTerminal(1) <cr>" },
    ["<A-i>"] = { "<cmd> lua require('harpoon.term').gotoTerminal(2) <cr>" },
    ["<A-o>"] = { "<cmd> lua require('harpoon.term').gotoTerminal(3) <cr>" },
    ["<A-p>"] = { "<cmd> lua require('harpoon.term').gotoTerminal(4) <cr>" },

    -- git
    ["<leader>gl"] = {"<cmd> LazyGit <CR>"},

    -- misc
    ["<leader>pf"] = {"<cmd> lua print(vim.fn.expand('%')) <CR>"},
    -- 
  },
  v = {
    ["<leader>cc"] = {"<cmd> lua require('osc52').copy_visual() <CR>"},
    -- [">"] = { ">gv", "indent"},
  },
}

M.dap = {
  plugin = true,
  v = {
    ["<leader>de"] = {"<cmd> lua require('dapui').eval() <CR>"},
  },
  n = {
    ["<leader>db"] = {"<cmd> DapToggleBreakpoint <CR>"},
    ["<leader>du"] = {"<cmd> lua require('dapui').toggle() <CR>"},
    ["<leader>dr"] = {"<cmd> lua require('dapui').float_element('repl') <CR>"},
    ["<leader>de"] = {"<cmd> lua require('dapui').eval() <CR>"},
    ["<leader>dk"] = {"<cmd> lua require('dap').down() <CR>"},
    ["<leader>dl"] = {"<cmd> lua require('dap').up() <CR>"},
    ["<leader>df"] = {"<cmd> lua require('dap').focus_frame() <CR>"},

    ["<leader>pi"] = {"<cmd> PyrightOrganizeImports <CR>"},
    ["<leader>pp"] = {"<cmd> PyrightSetPythonPath venv/bin/python <CR>"},

    ["<F6>"] = {"<cmd> DapToggleBreakpoint <CR>"},
    ["<F8>"] = {"<cmd> DapStepOver <CR>"},
    ["<F7>"] = {"<cmd> DapStepInto <CR>"},
    ["<F9>"] = {function()
      -- (Re-)reads launch.json if present
      if vim.fn.filereadable(".vscode/launch.json") then
        require("dap.ext.vscode").load_launchjs(nil, { cpptools = { "c", "cpp" } })
      end
      require("dap").continue()
    end},
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
    ["<leader>cs"] = {"<cmd> CMakeStop <CR>"},
    ["<leader>ctr"] = {"<cmd> CMakeSelectLaunchTarget <CR>"},
    ["<leader>ctb"] = {"<cmd> CMakeSelectBuildTarget <CR>"},
  }
}
-- more keybinds!
-- move to next match immediately, tab through stuff
vim.g['sneak#label'] = 1

-- always go the same way.
vim.g['sneak#absolute_dir'] = 1

-- case dependent on ignorecase+smartcase
vim.g['sneak#use_ic_scs'] = 1

vim.g['sneak#label_esc'] = "<c-c>"

vim.g['sneak#s_next'] = "<c-c>"

vim.keymap.set({'n', 'v'}, 's', '<Plug>Sneak_s', {remap = true})
vim.keymap.set({'n', 'v'}, 'S', '<Plug>Sneak_S', {remap = true})
vim.keymap.set('', 'f', '<Plug>Sneak_f', {remap = true})
vim.keymap.set('', 'F', '<Plug>Sneak_F', {remap = true})
vim.keymap.set('', 't', '<Plug>Sneak_t', {remap = true})
vim.keymap.set('', 'T', '<Plug>Sneak_T', {remap = true})

function go_to_file_col()
  -- grab current line and match it against the regexp
  local current_line = vim.api.nvim_get_current_line()
  local file, line = current_line:match("(/[^:]+):([0-9]+)")

  if not file then
    file, line = current_line:match("File \"(.+)\", line ([0-9]+)")
  end

  if file and line then

    local current_window = vim.api.nvim_win_get_number(vim.api.nvim_get_current_win())
    local windows = vim.api.nvim_tabpage_list_wins(0)

    for i, v in ipairs(windows) do
      -- jump to previous window
      if vim.api.nvim_win_get_number(v) == current_window and i > 1 then
        vim.api.nvim_set_current_win(windows[i - 1])
        break
      end
    end

    -- open the file
    vim.cmd(string.format(":edit %s", file))
    vim.cmd(string.format(":%d", line))
  end
end

vim.keymap.set({'n', 't'}, 'gf', go_to_file_col, {remap = true})

return M
