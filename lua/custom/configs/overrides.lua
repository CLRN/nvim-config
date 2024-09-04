local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "python",
    "json",
    "yaml",
    "cmake",
    "cpp",
    "asm",
  },
  indent = {
    enable = true,
    disable = {
      "cpp",
    },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",

    -- c/cpp stuff
    "clang-format",
    "codelldb",
    "cpptools",
    "cmake-language-server",

    -- python
    "black",
    "debugpy",
    "mypy",
    "ruff",
    "pyright",
    "isort",

    -- shell
    "beautysh",
    "curlylint",

    -- spell checks
    "typos-lsp",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

return M
