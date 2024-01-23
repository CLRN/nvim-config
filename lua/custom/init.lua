-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
require "custom.configs.firenvim"

vim.opt.spelllang = "en_us"
vim.opt.spell = false

local original = vim.fn.setqflist
vim.fn.setqflist = function(list, action, what)
  if not what then
    original(list, action)
    return
  end

  local transformed_lines = {}

  for _, line in ipairs(what.lines or {}) do
    local stripped_line = line:gsub("\x1b[[0-9][:;0-9]*[mK]", "")
    table.insert(transformed_lines, stripped_line)
  end

  original(list, action, { lines = transformed_lines })
end

-- vim.api.nvim_create_autocmd({ "BufRead", "BufNew" }, {
--   pattern = "*.ipynb",
--   command = "setfiletype jupyter",
-- })
if not vim.env.VIRTUAL_ENV then
  vim.g.python3_host_prog = "/usr/local/bin/python3"
else
  vim.g.python3_host_prog = vim.env.VIRTUAL_ENV .. "/bin/python3"
end
vim.g.loaded_remote_plugins = vim.fn.expand "$HOME/.local/share/nvim/rplugin.vim"
local enable_providers = {
  "python3_provider",
}

for _, plugin in pairs(enable_providers) do
  vim.g["loaded_" .. plugin] = nil
  vim.cmd("runtime " .. plugin)
end

if vim.loop.fs_stat(vim.g.loaded_remote_plugins) then
  vim.cmd(string.format("source %s", vim.g.loaded_remote_plugins))
end
