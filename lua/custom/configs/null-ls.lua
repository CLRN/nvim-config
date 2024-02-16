local null_ls = require "null-ls"

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local opts = {
  sources = {
    null_ls.builtins.diagnostics.mypy,
    null_ls.builtins.diagnostics.ruff,
    null_ls.builtins.formatting.prettier.with { filetypes = { "markdown", "css" } },
    -- null_ls.builtins.formatting.clang_format,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.beautysh,
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
    command = os.execute "which bde-format-15 > /dev/null" == 0 and "bde-format-15" or "clang-format",
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
