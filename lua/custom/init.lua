-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
require("custom.configs.firenvim")

vim.opt.spelllang = 'en_us'
vim.opt.spell = false

local original = vim.fn.setqflist
vim.fn.setqflist = function (list, action, what)
    local transformed_lines = {}

    for _, line in ipairs((what or {}).lines or {}) do
       local stripped_line = line:gsub("\x1b[[0-9][:;0-9]*[mK]", '')
       table.insert(transformed_lines, stripped_line)
    end

    original(list, action, { lines = transformed_lines })
end
