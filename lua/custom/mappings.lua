---@type MappingsTable
local M = {}

function CleanTerminal()
  vim.opt_local.scrollback = 1

  vim.api.nvim_command "startinsert"
  vim.api.nvim_feedkeys("reset", "t", false)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<cr>", true, false, true), "t", true)

  vim.opt_local.scrollback = 10000
end

M.general = {
  t = {
    ["<C-x>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:redrawstatus<CR>", true, true, true),
      "Escape terminal mode",
    },

    ["<A-q>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:tabprevious<CR>", true, true, true),
      "Escape and go to tab",
    },
    ["<A-t>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>:tabnext<CR>", true, true, true), "Escape and go to tab" },

    -- switch between windows
    ["<C-j>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>h", true, true, true), "Escape and go to window" },
    ["<C-'>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>l", true, true, true), "Escape and go to window" },
    ["<C-k>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>j", true, true, true), "Escape and go to window" },
    ["<C-l>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-w>k", true, true, true), "Escape and go to window" },

    -- back
    ["<C-o>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N><C-o>", true, true, true), "Escape and go back" },

    ["<A-x>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[1]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-c>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[2]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-v>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[3]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-s>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[4]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-d>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[5]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-f>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[6]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-w>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[7]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-e>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[8]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },
    ["<A-r>"] = {
      vim.api.nvim_replace_termcodes(
        '<C-\\><C-N>:lua vim.cmd("b" .. require("nvchad.tabufline").bufilter()[9]) <cr>',
        true,
        true,
        true
      ),
      "Escape and go to buffer",
    },

    -- harpoon
    ["<A-y>"] = {
      vim.api.nvim_replace_termcodes(
        "<C-\\><C-N>:lua require('harpoon.ui').toggle_quick_menu() <cr>",
        true,
        true,
        true
      ),
      "Escape and go to harpoon",
    },

    ["<A-j>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(1) <cr>", true, true, true),
      "Escape and go to harpoon",
    },
    ["<A-k>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(2) <cr>", true, true, true),
      "Escape and go to harpoon",
    },
    ["<A-l>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(3) <cr>", true, true, true),
      "Escape and go to harpoon",
    },
    ["<A-'>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.ui').nav_file(4) <cr>", true, true, true),
      "Escape and go to harpoon",
    },

    ["<A-u>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(1) <cr>", true, true, true),
      "Escape and go to harpoon term",
    },
    ["<A-i>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(2) <cr>", true, true, true),
      "Escape and go to harpoon term",
    },
    ["<A-o>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(3) <cr>", true, true, true),
      "Escape and go to harpoon term",
    },
    ["<A-p>"] = {
      vim.api.nvim_replace_termcodes("<C-\\><C-N>:lua require('harpoon.term').gotoTerminal(4) <cr>", true, true, true),
      "Escape and go to harpoon term",
    },
  },

  n = {
    -- terminal
    ["<leader>tr"] = { CleanTerminal, "Clean terminal" },
    ["<leader>tn"] = { "<cmd> tabnew <CR>" },
    ["<leader>tt"] = { "<cmd> tabnew | terminal <CR>" },
    ["<leader>tx"] = { "<cmd> tabclose <CR>" },

    ["<leader>sc"] = { "<cmd> Telescope commands <CR>" },
    ["<leader>sk"] = { "<cmd> Telescope keymaps <CR>" },
    ["<leader>sh"] = { "<cmd> Telescope command_history <CR>" },
    ["<leader>sn"] = { "<cmd> Telescope notify <CR>" },
    ["<leader>sb"] = { "<cmd> Telescope buffers <CR>" },
    ["<leader>sj"] = { "<cmd> Telescope jumplist <CR>" },
    ["<leader>ss"] = { "<cmd> Telescope lsp_workspace_symbols <CR>" },
    ["<leader>sd"] = { "<cmd> Telescope diagnostics <CR>" },

    ["<A-x>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[1])
      end,
      "Go to buffer 1",
    },
    ["<A-c>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[2])
      end,
      "Go to buffer 2",
    },
    ["<A-v>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[3])
      end,
      "Go to buffer 3",
    },
    ["<A-s>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[4])
      end,
      "Go to buffer 4",
    },
    ["<A-d>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[5])
      end,
      "Go to buffer 5",
    },
    ["<A-f>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[6])
      end,
      "Go to buffer 6",
    },
    ["<A-w>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[7])
      end,
      "Go to buffer 4",
    },
    ["<A-e>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[8])
      end,
      "Go to buffer 5",
    },
    ["<A-r>"] = {
      function()
        vim.cmd("b" .. require("nvchad.tabufline").bufilter()[9])
      end,
      "Go to buffer 6",
    },

    ["<A-q>"] = { "<cmd> tabprevious<CR>", "Go to prev tab" },
    ["<A-t>"] = { "<cmd> tabnext<CR>", "Go to next tab" },

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
    ["<leader>gl"] = { "<cmd> LazyGit <CR>" },

    -- misc
    ["<leader>pf"] = { "<cmd> lua print(vim.fn.expand('%')) <CR>" },

    ["<leader>ne"] = { "<cmd> NoiceErrors <CR>", "NoiceErrors" },
    ["<leader>nh"] = { "<cmd> NoiceHistory <CR>", "NoiceHistory" },
    ["<leader>nl"] = { "<cmd> NoiceLast <CR>", "NoiceLast" },
    ["<leader>nt"] = { "<cmd> NoiceTelescope <CR>", "NoiceTelescope" },
  },
  v = {
    -- [">"] = { ">gv", "indent"},
  },
}

M.dap = {
  plugin = true,
  v = {
    ["<leader>de"] = { "<cmd> lua require('dapui').eval() <CR>" },
  },
  n = {
    ["<leader>db"] = { "<cmd> DapToggleBreakpoint <CR>" },
    ["<leader>dc"] = {
      function()
        local input = vim.fn.input "condition: "
        require("dap").toggle_breakpoint(input)
      end,
    },
    ["<leader>du"] = { "<cmd> lua require('dapui').toggle() <CR>" },
    ["<leader>dr"] = { "<cmd> lua require('dapui').float_element('repl') <CR>" },
    ["<leader>de"] = { "<cmd> lua require('dapui').eval() <CR>" },
    ["<leader>dk"] = { "<cmd> lua require('dap').down() <CR>" },
    ["<leader>dl"] = { "<cmd> lua require('dap').up() <CR>" },
    ["<leader>df"] = { "<cmd> lua require('dap').focus_frame() <CR>" },

    ["<leader>pi"] = { "<cmd> PyrightOrganizeImports <CR>" },
    ["<leader>pp"] = { "<cmd> PyrightSetPythonPath " .. (vim.env.VIRTUAL_ENV or "") .. " <CR>" },

    ["<F5>"] = {
      function()
        require("dap").step_out()
      end,
    },
    ["<F8>"] = { "<cmd> DapStepOver <CR>" },
    ["<F7>"] = { "<cmd> DapStepInto <CR>" },
    ["<F9>"] = {
      function()
        -- (Re-)reads launch.json if present
        pcall(vim.cmd, "wa")
        if vim.fn.filereadable ".vscode/launch.json" then
          local vscode = require "dap.ext.vscode"
          -- pcall(vscode.load_launchjs, nil, { cpptools = { "c", "cpp" } })
        end
        require("dap").continue()
      end,
    },
    ["<F4>"] = { "<cmd> DapTerminate <CR>" },
  },
}

M.dap_python = {
  plugin = true,
  n = {
    ["<leader>dpr"] = {
      function()
        require("dap-python").test_method()
      end,
    },
  },
}

M.cmake_tools = {
  plugin = false,
  n = {
    ["<leader>cb"] = { "<cmd> CMakeBuild <CR>" },
    ["<leader>cd"] = { "<cmd> CMakeDebug <CR>" },
    ["<leader>cr"] = { "<cmd> CMakeRun <CR>" },
    ["<leader>cc"] = { "<cmd> CMakeRunTest <CR>" },
    ["<leader>cs"] = { "<cmd> CMakeStopExecutor <CR>" },
    ["<leader>cts"] = { "<cmd> CMakeTargetSettings <CR>" },
    ["<leader>ctb"] = {
      function()
        require("cmake-tools").select_build_target(function()
          vim.cmd "redrawstatus"
        end)
      end,
      "Select build target",
    },
    ["<leader>ctr"] = {
      function()
        require("cmake-tools").select_launch_target(function()
          vim.cmd "redrawstatus"
        end)
      end,
      "Select launch target",
    },
  },
}
-- more keybinds!
-- move to next match immediately, tab through stuff
vim.g["sneak#label"] = 1

-- case dependent on ignorecase+smartcase
vim.g["sneak#use_ic_scs"] = 1

vim.keymap.set({ "n", "v" }, "s", "<Plug>Sneak_s", { remap = true })
vim.keymap.set({ "n", "v" }, "S", "<Plug>Sneak_S", { remap = true })
-- vim.keymap.set("", "f", "<Plug>Sneak_f", { remap = true })
-- vim.keymap.set("", "F", "<Plug>Sneak_F", { remap = true })
-- vim.keymap.set("", "t", "<Plug>Sneak_t", { remap = true })
-- vim.keymap.set("", "T", "<Plug>Sneak_T", { remap = true })

vim.keymap.set("v", "$", "g_", { remap = true })

function GoToFileCol()
  -- grab current line and match it against the regexp
  local current_line = vim.api.nvim_get_current_line()
  local file, line = current_line:match "(/?[^:]+):([0-9]+)"

  if not file then
    file, line = current_line:match 'File "(.+)", line ([0-9]+)'
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

vim.keymap.set({ "n", "t" }, "<leader>gf", GoToFileCol, { remap = true })

return M
