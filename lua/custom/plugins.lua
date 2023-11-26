local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options
  {
    "jose-elias-alvarez/null-ls.nvim",
    ft = {"python"},
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },
  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason
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
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(
        {
          layouts = { {
            elements = { {
              id = "scopes",
              size = 0.70
            }, {
                id = "breakpoints",
                size = 0.05
              }, {
                id = "stacks",
                size = 0.05
              }, {
                id = "watches",
                size = 0.05
              }, {
                id = "repl",
                size = 0.15
              } },
            position = "left",
            size = 50
          }, {
              elements = { {
                  id = "console",
                  size = 1,
                } },
              position = "bottom",
              size = 20
            }},
          mappings = {
            edit = "e",
            expand = { "<CR>", "<2-LeftMouse>" },
            open = "o",
            remove = "d",
            repl = "r",
            toggle = "t"
          },
        }
      )
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end
  },
  {
    "mfussenegger/nvim-dap",
    config = function(_, opts)
      require("core.utils").load_mappings("dap")

      local dap = require('dap')
      local dapui = require("dapui")

      dap.adapters.cppdbg = {
        id = 'cppdbg',
        type = 'executable',
        command = 'OpenDebugAD7',
      }

      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "cppdbg",
          request = "launch",
          program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
          stopAtEntry = true,
          setupCommands = {
            {
              text = '-enable-pretty-printing',
              description =  'enable pretty printing',
              ignoreFailures = false
            },
          },
        }
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
    end
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function(_, opts)
      -- local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"

      local cwd = vim.fn.getcwd()
      local path = ""
      if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
        path = cwd .. '/venv/bin/python'
      elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
        path = cwd .. '/.venv/bin/python'
      else
        path = "python3"
      end

      require("dap-python").setup(path)
      require("core.utils").load_mappings("dap_python")
      require("dap.ext.vscode").load_launchjs(nil, {})
      require("nvim-dap-virtual-text").setup(nil, {})
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = {"mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter"},
    config = function(_, opts)
      require("nvim-dap-virtual-text").setup {
        enabled = true,                        -- enable this plugin (the default)
        enabled_commands = true,               -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
        highlight_changed_variables = true,    -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
        highlight_new_as_changed = false,      -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
        show_stop_reason = true,               -- show stop reason when stopped for exceptions
        commented = false,                     -- prefix virtual text with comment string
        only_first_definition = true,          -- only show virtual text at first definition (if there are multiple)
        all_references = false,                -- show virtual text on all all references of the variable (not only definitions)
        clear_on_continue = false,             -- clear virtual text on "continue" (might cause flickering when stepping)
        --- A callback that determines how a variable is displayed or whether it should be omitted
        --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
        --- @param buf number
        --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
        --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
        --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
        --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
        display_callback = function(variable, buf, stackframe, node, options)
          if options.virt_text_pos == 'inline' then
            return ' = ' .. variable.value
          else
            return variable.name .. ' = ' .. variable.value
          end
        end,
        -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
        virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',

        -- experimental features:
        all_frames = false,                    -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
        virt_lines = false,                    -- show virtual lines instead of virtual text (will flicker!)
        virt_text_win_col = nil                -- position the virtual text at a fixed window column (starting from the first text column) ,
        -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
      }
    end,
  },
  {
    "Civitasv/cmake-tools.nvim",
    lazy = true,
    ft = {"cmake", "cpp"},
    config = function(_, opts)
      require("cmake-tools").setup {
        cmake_command = "cmake", -- this is used to specify cmake command path
        cmake_regenerate_on_save = true, -- auto generate when save CMakeLists.txt
        --
        cmake_generate_options = { 
          "-DCMAKE_EXPORT_COMPILE_COMMANDS=1", 
          "-DCMAKE_VERBOSE_MAKEFILE=OFF",
          "-DCMAKE_TOOLCHAIN_FILE=/bb/feeds/feeds20-support/feeds20-dev-distros/series/stable/refroot/amd64/opt/bb/share/plink/BBToolchain64.cmake",
          "-DCMAKE_INSTALL_LIBDIR=.",
          "-DCMAKE_BUILD_TYPE=Debug",
          "-DCMAKE_CXX_STANDARD=17",
          "-DBUILDID=dev",
          "-DCMAKE_OUTPUT_DIR=.",
        }, -- this will be passed when invoke `CMakeGenerate`
        cmake_build_options = {}, -- this will be passed when invoke `CMakeBuild`
        -- support macro expansion:
        --       ${kit}
        --       ${kitGenerator}
        --       ${variant:xx}
        cmake_build_directory = "cmake-build/${variant:buildType}", -- this is used to specify generate directory for cmake, allows macro expansion
        cmake_soft_link_compile_commands = true, -- this will automatically make a soft link from compile commands file to project root dir
        cmake_compile_commands_from_lsp = false, -- this will automatically set compile commands file location using lsp, to use it, please set `cmake_soft_link_compile_commands` to false
        cmake_kits_path = nil, -- this is used to specify global cmake kits path, see CMakeKits for detailed usage
        cmake_variants_message = {
          short = { show = true }, -- whether to show short message
          long = { show = true, max_length = 40 }, -- whether to show long message
        },
        cmake_dap_configuration = { -- debug settings for cmake
          name = "cpp",
          type = "cppdbg",
          request = "launch",
          stopOnEntry = false,
          runInTerminal = true,
          console = "integratedTerminal",
          setupCommands = {
            {
              text = '-enable-pretty-printing',
              description =  'enable pretty printing',
              ignoreFailures = false
            },
          },
        },
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
            keep_terminal_static_location = true, -- Static location of the viewport if avialable

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
    end
  },
  {
    lazy = false,
    "kdheepak/lazygit.nvim",
    dependencies =  {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim"
    },
    config = function()
      require("telescope").load_extension("lazygit")
    end,
  },
  {
    lazy = false,
    "ThePrimeagen/harpoon",
    dependencies =  {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim"
    },
    config = function()
      require("telescope").load_extension("harpoon")
    end,
  },
  {
    lazy = false,
    "justinmk/vim-sneak"
  },
  {
    lazy = false,
    "tpope/vim-surround"
  }
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


}

return plugins
