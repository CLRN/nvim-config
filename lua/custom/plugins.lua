local overrides = require "custom.configs.overrides"

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options
  {
    event = "VeryLazy",
    "jose-elias-alvarez/null-ls.nvim",
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },
  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },

  -- Install a plugin
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- python debugging
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"
      dapui.setup {
        layouts = {
          {
            elements = { {
              id = "console",
              size = 1,
            } },
            position = "bottom",
            size = 15,
          },
          {
            elements = {
              {
                id = "scopes",
                size = 0.50,
              },
              {
                id = "breakpoints",
                size = 0.10,
              },
              {
                id = "stacks",
                size = 0.40,
              },
            },
            position = "left",
            size = 60,
          },
        },
        mappings = {
          edit = "e",
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          repl = "r",
          toggle = "t",
        },
      }
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    config = function(_, opts)
      require("core.utils").load_mappings "dap"

      local dap = require "dap"
      local dapui = require "dapui"

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.adapters.cppdbg_rosetta = {
        id = "cppdbg",
        type = "executable",
        command = vim.fn.expand "$HOME/.config/nvim/dap_rosetta",
      }

      dap.adapters.cppdbg = {
        id = "cppdbg",
        type = "executable",
        command = "OpenDebugAD7",
      }

      dap.configurations.cpp = {
        {
          name = "Current CMake target(gdb)",
          type = "cppdbg",
          request = "launch",
          program = function()
            local status, cmake = pcall(require, "cmake-tools")
            if status then
              local target = cmake.get_launch_target()
              if target then
                return cmake.get_launch_path(target) .. target
              end
            end

            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtEntry = true,
          runInTerminal = true,
          console = "integratedTerminal",
          setupCommands = {
            {
              text = "-enable-pretty-printing",
              description = "enable pretty printing",
              ignoreFailures = false,
            },
          },
        },
      }
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function(_, opts)
      local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"

      require("dap-python").setup(path)
      require("core.utils").load_mappings "dap_python"
      -- require("dap.ext.vscode").load_launchjs(nil, {})
      require("nvim-dap-virtual-text").setup(nil, {})
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    config = function(_, opts)
      require("nvim-dap-virtual-text").setup {
        enabled = true, -- enable this plugin (the default)
        enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
        highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
        highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
        show_stop_reason = true, -- show stop reason when stopped for exceptions
        commented = false, -- prefix virtual text with comment string
        only_first_definition = true, -- only show virtual text at first definition (if there are multiple)
        all_references = false, -- show virtual text on all all references of the variable (not only definitions)
        clear_on_continue = false, -- clear virtual text on "continue" (might cause flickering when stepping)
        --- A callback that determines how a variable is displayed or whether it should be omitted
        --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
        --- @param buf number
        --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
        --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
        --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
        --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
        display_callback = function(variable, buf, stackframe, node, options)
          if options.virt_text_pos == "inline" then
            return " = " .. variable.value
          else
            return variable.name .. " = " .. variable.value
          end
        end,
        -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
        virt_text_pos = "eol",

        -- experimental features:
        all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
        virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
        virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
        -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
      }
    end,
  },
  {
    "CLRN/cmake-tools.nvim",
    ft = { "cmake", "cpp" },
    enabled = function()
      return vim.fn.filewritable "CMakeLists.txt" == 1
    end,
    config = function(_, opts)
      local gen_opts_bb = {
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        "-DCMAKE_VERBOSE_MAKEFILE=OFF",
        "-DCMAKE_TOOLCHAIN_FILE="
          .. (os.getenv "DISTRIBUTION_REFROOT" or "")
          .. "/opt/bb/share/plink/BBToolchain64.cmake",
        "-DCMAKE_INSTALL_LIBDIR=.",
        "-DBUILDID=dev",
        "-DCMAKE_OUTPUT_DIR=.",
        "-GUnix Makefiles",
      }

      local gen_opts_clang = {
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        "-DCMAKE_C_COMPILER=clang",
        "-DCMAKE_CXX_COMPILER=clang++",
        "-GNinja",
      }

      local dap_gdb = {
        name = "cpp",
        type = "cppdbg",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
        console = "integratedTerminal",
        setupCommands = {
          {
            text = "-enable-pretty-printing",
            description = "enable pretty printing",
            ignoreFailures = false,
          },
        },
      }

      local dap_lldb = {
        name = "cpp",
        type = "codelldb",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
        console = "integratedTerminal",
      }

      local is_bb = vim.fn.executable "/opt/bb/bin/g++" == 1
      local dap = dap_lldb
      if is_bb then
        if #vim.fn.system "ps a -q 1 | grep rosetta" > 0 then
          dap_gdb.type = "cppdbg_rosetta"
          table.insert(dap_gdb.setupCommands, {
            text = "handle SIGSEGV nostop noprint",
            description = "ignore SIGSEGV caused by Rosetta",
            ignoreFailures = false,
          })
        end
        dap = dap_gdb
      end

      require("cmake-tools").setup {
        cmake_command = "cmake", -- this is used to specify cmake command path
        cmake_regenerate_on_save = true, -- auto generate when save CMakeLists.txt
        --
        cmake_generate_options = is_bb and gen_opts_bb or gen_opts_clang, -- this will be passed when invoke `CMakeGenerate`
        cmake_build_options = { "-j", "12" }, -- this will be passed when invoke `CMakeBuild`
        cmake_build_directory = "cmake-build/${variant:buildType}", -- this is used to specify generate directory for cmake, allows macro expansion
        cmake_soft_link_compile_commands = false, -- this will automatically make a soft link from compile commands file to project root dir
        cmake_compile_commands_from_lsp = true,
        cmake_kits_path = nil, -- this is used to specify global cmake kits path, see CMakeKits for detailed usage
        cmake_variants_message = {
          short = { show = true }, -- whether to show short message
          long = { show = true, max_length = 40 }, -- whether to show long message
        },
        cmake_dap_configuration = dap,
        cmake_executor = { -- executor to use
          name = "quickfix", -- name of the executor
          opts = {}, -- the options the executor will get, possible values depend on the executor type. See `default_opts` for possible values.
          default_opts = { -- a list of default and possible values for executors
            quickfix = {
              show = "always", -- "always", "only_on_error"
              position = "belowright", -- "bottom", "top"
              size = 10,
            },
            overseer = {
              new_task_opts = {}, -- options to pass into the `overseer.new_task` command
              on_new_task = function(task) end, -- a function that gets overseer.Task when it is created, before calling `task:start`
            },
            terminal = {}, -- terminal executor uses the values in cmake_terminal
          },
        },
        cmake_terminal = {
          name = "terminal",
          opts = {
            name = "Main Terminal",
            prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
            split_direction = "horizontal", -- "horizontal", "vertical"
            split_size = 20,

            -- Window handling
            single_terminal_per_instance = true, -- Single viewport, multiple windows
            single_terminal_per_tab = true, -- Single viewport per tab
            keep_terminal_static_location = true, -- Static location of the viewport if available

            -- Running Tasks
            start_insert_in_launch_task = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
            start_insert_in_other_tasks = false, -- If you want to enter terminal with :startinsert upon launching all other cmake tasks in the terminal. Generally set as false
            focus_on_main_terminal = false, -- Focus on cmake terminal when cmake task is launched. Only used if executor is terminal.
            focus_on_launch_terminal = false, -- Focus on cmake launch terminal when executable target in launched.
          },
        },
        cmake_notifications = {
          enabled = true, -- show cmake execution progress in nvim-notify
          spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- icons used for progress display
          refresh_rate_ms = 100, -- how often to iterate icons
        },
      }
    end,
  },
  {
    event = "VeryLazy",
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension "lazygit"
    end,
  },
  {
    event = "VeryLazy",
    "ThePrimeagen/harpoon",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("telescope").load_extension "harpoon"
    end,
  },
  {
    event = "VeryLazy",
    "justinmk/vim-sneak",
  },
  {
    event = "VeryLazy",
    "tpope/vim-surround",
  },
  {
    lazy = false,
    "ojroques/nvim-osc52",
    config = function()
      local function copy(lines, _)
        require("osc52").copy(table.concat(lines, "\n"))
      end

      local function paste()
        return { vim.fn.split(vim.fn.getreg "", "\n"), vim.fn.getregtype "" }
      end

      vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = paste, ["*"] = paste },
      }

      require("osc52").setup {
        max_length = 0, -- Maximum length of selection (0 for no limit)
        silent = true, -- Disable message on successful copy
        trim = true, -- Trim surrounding whitespaces before copy
        tmux_passthrough = false, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
      }
    end,
  },

  -- { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' },
  -- {
  --   "junegunn/fzf",
  --   ft = { "cmake", "cpp", "python", "lua" },
  --   build = function()
  --     vim.fn["fzf#install"]()
  --   end,
  -- },

  {
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json", "yaml", "lua", "cmake" },
    "FotiadisM/tabset.nvim",
    config = function()
      require("tabset").setup {
        languages = {
          {
            filetypes = {
              "javascript",
              "typescript",
              "javascriptreact",
              "typescriptreact",
              "json",
              "yaml",
              "lua",
              "cmake",
            },
            config = {
              tabwidth = 2,
            },
          },
        },
      }
    end,
  },
  {
    "nvim-lua/plenary.nvim",
    event = "VeryLazy",
    config = function()
      require "custom.teddy"
    end,
  },

  {
    "3rd/image.nvim",
    event = {
      "FileType markdown,norg",
      "BufRead *.png,*.jpg,*.gif,*.webp,*.ipynb",
    },
    build = {
      "ueberzug --version",
      "magick --version",
      "luarocks --lua-version 5.1 --local install magick",
    },
    enabled = function()
      vim.fn.system "magick --version"
      return vim.v.shell_error == 0
    end,
    config = function()
      require "custom.configs.image"
    end,
  },

  {
    "taybart/b64.nvim",
  },

  {
    "CLRN/websocket.nvim",
    branch = "fix-multiple-frames-in-a-packet",
  },

  {
    "m00qek/baleia.nvim",
    config = function()
      require("baleia").setup {}
    end,
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    config = function()
      require("noice").setup {
        lsp = {
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          hover = {
            enabled = false,
          },
          signature = {
            enabled = false,
          },
          progress = {
            enabled = true,
          },
        },
        -- you can enable a preset for easier configuration
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false, -- add a border to hover docs and signature help
        },
        views = {
          cmdline_popup = {
            position = {
              row = 3,
              col = "50%",
            },
            size = {
              width = 60,
              height = "auto",
            },
          },
          popupmenu = {
            relative = "editor",
            position = {
              row = 8,
              col = "50%",
            },
            size = {
              width = 60,
              height = 10,
            },
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
            },
          },
        },
      }
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },

  {
    "anuvyklack/hydra.nvim",
    event = "VeryLazy",
    config = function()
      local Hydra = require "hydra"

      local function cmd(command)
        return table.concat { ":", command, "<cr>" }
      end

      local hint = [[
 Move      Size          Splits
 ----- --------------  -----------
 ^ ^ _l_ ^ ^   ^ ^  _<Up>_ ^ ^     _s_: horizontally
 _j_ ^ ^ _'_ _<Left>_ _<Right>_  _v_: vertically
 ^ ^ _k_ ^ ^   ^ ^ _<Down>_ ^ ^    _c_: close

 _=_: equalize           _m_: toggle maximize
 _r_: Rotate down/right  _R_: rotate up/left
 ^
 _q_:     exit          _<Esc>_: exit
]]

      local opts = { exit = true, nowait = true }

      Hydra {
        name = "Windows",
        hint = hint,
        config = {
          color = "pink",
          invoke_on_body = true,
          hint = {
            position = "middle",
            border = "rounded",
          },
        },
        mode = "n",
        body = "<leader>ww",
        heads = {
          { "s", cmd "split", opts },
          { "v", cmd "vsplit", opts },
          { "c", cmd "close", opts }, -- close current window
          { "m", cmd "WindowsMaximize", opts }, -- maximize current window
          -- window resizing
          { "=", cmd "wincmd =" },
          { "<Up>", cmd "wincmd +" },
          { "<Down>", cmd "wincmd -" },
          { "<Left>", cmd "wincmd <" },
          { "<Right>", cmd "wincmd >" },
          -- move window around
          { "j", cmd "wincmd H" },
          { "k", cmd "wincmd J" },
          { "l", cmd "wincmd K" },
          { "'", cmd "wincmd L" },
          -- rotate window
          { "r", cmd "wincmd r" },
          { "R", cmd "wincmd R" },
          -- quit
          { "q", nil, opts },
          { "<Esc>", nil, opts },
        },
      }
    end,
  },

  {
    "kawre/leetcode.nvim",
    lazy = vim.fn.argv()[1] ~= "lc",
    opts = {
      arg = "lc",
      injector = {
        ["cpp"] = {
          before = {
            "#include <vector>",
            "#include <string>",
            "#include <map>",
            "#include <unordered_map>",
            "#include <algorithm>",
            "#include <iostream>",
            "using namespace std;",
            "// Solution() { ios_base::sync_with_stdio(false); cin.tie(NULL); cout.tie(NULL); }",
          },
        },
      },
      description = {
        position = "right",
      },
      console = {
        dir = "col",
      },
      hooks = {
        ["question_enter"] = {
          -- For question
          function(q)
            local bufnr = q.bufnr

            vim.b[bufnr].copilot_enabled = false

            vim.keymap.set("n", "<localleader>l", "<Cmd>Leet list<CR>", { buffer = bufnr, desc = "LeetCode list" })
            vim.keymap.set("n", "<localleader>r", "<Cmd>Leet run<CR>", { buffer = bufnr, desc = "LeetCode run" })
            vim.keymap.set("n", "<localleader>s", "<Cmd>Leet submit<CR>", { buffer = bufnr, desc = "LeetCode submit" })
            vim.keymap.set("n", "<localleader>o", "<Cmd>Leet open<CR>", { buffer = bufnr, desc = "LeetCode open" })
            vim.keymap.set(
              "n",
              "<localleader>i",
              "<Cmd>Leet info<CR>",
              { buffer = bufnr, desc = "LeetCode information" }
            )
            vim.keymap.set(
              "n",
              "<localleader>d",
              "<Cmd>Leet desc<CR>",
              { buffer = bufnr, desc = "LeetCode description" }
            )
            vim.keymap.set(
              "n",
              "<localleader>c",
              "<Cmd>Leet console<CR>",
              { buffer = bufnr, desc = "LeetCode console" }
            )
          end,
          -- For question description
          function(q)
            local winid = q.description.winid

            vim.wo[winid].wrap = true
            vim.wo[winid].showbreak = "NONE"
            vim.wo[winid].foldcolumn = "0"
          end,
        },
      },
      image_support = true,
    },
  },

  {
    "aaronhallaert/advanced-git-search.nvim",
    event = "VeryLazy",
    config = function()
      require("telescope").load_extension "advanced_git_search"
      vim.api.nvim_set_keymap(
        "n",
        "<leader>sg",
        "<cmd>AdvancedGitSearch<cr>",
        { noremap = true, silent = true, desc = "AdvancedGitSearch" }
      )
      vim.api.nvim_set_keymap(
        "v",
        "<leader>sg",
        "<cmd>'<,'>AdvancedGitSearch diff_commit_line<cr>",
        { noremap = false, silent = true, desc = "Search file commits (advanced)" }
      )
    end,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "tpope/vim-fugitive",
      "tpope/vim-rhubarb",
    },
  },
  {
    "chomosuke/term-edit.nvim",
    event = "VeryLazy",
    config = function()
      require("term-edit").setup {
        prompt_end = " ",
      }
    end,
  },

  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    event = "VeryLazy",
    config = function()
      require("telescope").load_extension "live_grep_args"

      vim.api.nvim_set_keymap(
        "n",
        "<leader>fg",
        ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
        { noremap = true, silent = true, desc = "Ripgrep advanced search" }
      )
    end,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
  },

  {
    "tomasky/bookmarks.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    event = "VeryLazy",
    config = function()
      require("bookmarks").setup {
        -- sign_priority = 8, --set bookmark sign priority to cover other sign
        save_file = vim.fn.expand "$HOME/.bookmarks", -- bookmarks save file path
        keywords = {
          ["@t"] = "☑️ ", -- mark annotation startswith @t ,signs this icon as `Todo`
          ["@w"] = "⚠️ ", -- mark annotation startswith @w ,signs this icon as `Warn`
          ["@f"] = "⛏ ", -- mark annotation startswith @f ,signs this icon as `Fix`
          ["@n"] = "󰈚 ", -- mark annotation startswith @n ,signs this icon as `Note`
        },
        on_attach = function(bufnr)
          local bm = require "bookmarks"
          local map = vim.keymap.set
          map("n", "mm", bm.bookmark_toggle) -- add or remove bookmark at current line
          map("n", "ma", bm.bookmark_ann) -- add or edit mark annotation at current line
          map("n", "mc", bm.bookmark_clean) -- clean all marks in local buffer
          map("n", "m'", bm.bookmark_next) -- jump to next mark in local buffer
          map("n", "mj", bm.bookmark_prev) -- jump to previous mark in local buffer
          map("n", "ml", bm.bookmark_list) -- show marked file list in quickfix window
          map("n", "mx", bm.bookmark_clear_all) -- removes all bookmarks
        end,
      }
      require("telescope").load_extension "bookmarks"

      vim.api.nvim_set_keymap(
        "n",
        "ms",
        ":lua require('telescope').extensions.bookmarks.list()<CR>",
        { noremap = true, silent = true, desc = "Search bookmarks" }
      )
    end,
  },

  {
    "CLRN/gdb-disasm.nvim",
    event = "VeryLazy",
    enabled = function()
      return vim.fn.filewritable "CMakeLists.txt" == 1
    end,
    config = function()
      local disasm = require "gdbdisasm"
      disasm.setup {}

      local status, cmake = pcall(require, "cmake-tools")
      if not status then
        return
      end

      local target = cmake.get_build_target()
      if target then
        disasm.set_binary_path(cmake.get_build_target_path(target))
      end

      vim.keymap.set("n", "<leader>dai", disasm.toggle_inline_disasm, { desc = "Toggle disassembly" })
      vim.keymap.set("n", "<leader>das", disasm.save_current_state, { desc = "Save current session state" })
      vim.keymap.set("n", "<leader>dal", disasm.load_saved_state, { desc = "Load saved session" })
      vim.keymap.set("n", "<leader>dar", disasm.remove_saved_state, { desc = "Remove saved session" })
      vim.keymap.set("n", "<leader>dac", disasm.resolve_calls_under_the_cursor, { desc = "Jump to a call" })
      vim.keymap.set("n", "<leader>daw", disasm.new_window_disasm, { desc = "Disassemble to new window" })
      vim.keymap.set("n", "<leader>daq", disasm.stop, { desc = "Clean disassembly and quit GDB" })
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("render-markdown").setup {
        bullet = {
          left_pad = 2,
        },
      }
    end,
  },
  -- {
  --   "glacambre/firenvim",
  --
  --   -- Lazy load firenvim
  --   -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
  --   lazy = not vim.g.started_by_firenvim,
  --   build = function()
  --     vim.fn["firenvim#install"](0)
  --   end,
  -- },
  -- {
  --   "benlubas/molten-nvim",
  --   build = function()
  --     vim.fn["remote#host#UpdateRemotePlugins"]()
  --     vim.cmd(string.format("source %s", vim.g.loaded_remote_plugins))
  --   end,
  --   config = function()
  --     require "custom.configs.molten"
  --   end,
  -- },

  -- {
  --   "GCBallesteros/jupytext.nvim",
  --   config = true,
  --   lazy = false,
  -- },

  -- {
  --   "GCBallesteros/NotebookNavigator.nvim",
  --   event = "BufEnter *.ipynb",
  --   config = function()
  --     local nn = require "notebook-navigator"
  --     nn.setup {
  --       activate_hydra_keys = "<leader>h",
  --       repl_provider = "molten",
  --       show_hydra_hint = false,
  --       hydra_keys = {
  --         comment = "c",
  --         run = "<CR>",
  --         run_and_move = "<C-CR>",
  --         move_up = "l",
  --         move_down = "k",
  --         add_cell_before = "a",
  --         add_cell_after = "b",
  --       },
  --     }
  --   end,
  --   dependencies = {
  --     "echasnovski/mini.comment",
  --     "benlubas/molten-nvim",
  --     "anuvyklack/hydra.nvim",
  --     -- "3rd/image.nvim"
  --   },
  -- },

  -- {
  --   "kevinhwang91/nvim-bqf",
  --   ft = {"cmake", "cpp", "python", "lua"},
  -- }

  -- {
  --   lazy = false,
  --   'tanvirtin/vgit.nvim',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim'
  --   },
  --   config = function()
  --     require("vgit").setup()
  --   end,
  -- }
  -- {
  --   lazy = false,
  --   "rcarriga/nvim-notify",
  --   enabled = function()
  --     vim.fn.system "bbhost -q -w localhost sn2 fcldev"
  --     return vim.v.shell_error ~= 0
  --   end,
  --   config = function()
  --     require("telescope").load_extension "notify"
  --     vim.notify = require "notify"
  --   end,
  -- },
}

return plugins
