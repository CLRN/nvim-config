-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
require("custom.configs.firenvim")

vim.opt.spelllang = 'en_us'
vim.opt.spell = false
