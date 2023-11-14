local null_ls = require "null-ls"

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local opts = {
  sources = {
    null_ls.builtins.diagnostics.mypy,
    null_ls.builtins.diagnostics.ruff,
    null_ls.builtins.formatting.prettier.with { filetypes = { "html", "markdown", "css" } }, -- so prettier works only on these filetypes
    null_ls.builtins.formatting.clang_format,
    null_ls.builtins.formatting.stylua,

    -- python
    null_ls.builtins.formatting.black.with({
      extra_args = { "--line-length=120" }
    }),
    null_ls.builtins.formatting.isort,
  },
  on_attach = function(client, bufnr)
    print("attaching")
    if client.supports_method("textDocument/formatting") then
      print("supports")
      vim.api.nvim_clear_autocmds({
        group = augroup,
        buffer = bufnr,
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          print("formattings")
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end,
}

return opts
