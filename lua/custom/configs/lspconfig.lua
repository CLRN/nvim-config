local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table
local servers = { "cssls", "tsserver", "pyright", "cmake" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig.html.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    css = {
      lint = {
        validProperties = {},
      },
    },
  },
}

lspconfig.clangd.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "clangd", "--offset-encoding=utf-16" },
  on_new_config = function(new_config, new_cwd)
    local status, cmake = pcall(require, "cmake-tools")
    if status then
      cmake.clangd_on_new_config(new_config)
    end
  end,
}
