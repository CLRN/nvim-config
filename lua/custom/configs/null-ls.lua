local null_ls = require "null-ls"

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local ruff_diagnostics = require "none-ls.diagnostics.ruff"
local beautysh_formatting = require "none-ls.formatting.beautysh"

local opts = {
  sources = {
    null_ls.builtins.diagnostics.mypy,
    ruff_diagnostics,
    null_ls.builtins.formatting.prettier.with { filetypes = { "markdown", "css" } },
    -- null_ls.builtins.formatting.clang_format,
    null_ls.builtins.formatting.stylua.with { extra_args = { "--indent_type", "Spaces", "indent_width", "2" } },
    beautysh_formatting,
    null_ls.builtins.formatting.djhtml.with { filetypes = { "html", "htmldjango" } },

    -- python
    null_ls.builtins.formatting.black.with {
      extra_args = { "--line-length=120" },
    },
    null_ls.builtins.formatting.isort.with {
      extra_args = { "--line-length=120" },
    },
  },
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      vim.api.nvim_clear_autocmds {
        group = augroup,
        buffer = bufnr,
      }
      -- vim.api.nvim_create_autocmd("BufWritePre", {
      --   group = augroup,
      --   buffer = bufnr,
      --   callback = function()
      --     vim.lsp.buf.format({ bufnr = bufnr })
      --   end,
      -- })
    end
  end,
}

local bde_formatter = {
  method = { null_ls.methods.FORMATTING, null_ls.methods.RANGE_FORMATTING },
  filetypes = { "cpp" },
  generator = null_ls.formatter {
    command = vim.fn.executable "bde-format-15" == 1 and "bde-format-15" or "clang-format",
    to_stdin = true,
    args = require("null-ls.helpers").range_formatting_args_factory(
      { "--assume-filename", "$FILENAME" },
      "--offset",
      "--length",
      { use_length = true, row_offset = -1, col_offset = -1 }
    ),
  },
}
null_ls.register(bde_formatter)

return opts
