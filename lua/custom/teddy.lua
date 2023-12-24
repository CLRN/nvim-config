local popup = require "plenary.popup"

local function create_window()
  local width = 120
  local height = 20
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local bufnr = vim.api.nvim_create_buf(false, false)

  local win_id, _ = popup.create(bufnr, {
    title = "Edit command",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
  })

  return {
    bufnr = bufnr,
    win_id = win_id,
  }
end

local M = {}

function M.edit()
  local term_buf = vim.api.nvim_get_current_buf()
  local channel = nil
  for _, chan in pairs(vim.api.nvim_list_chans()) do
    if chan["buffer"] == term_buf then
      channel = chan["id"]
    end
  end

  if not channel then
    return
  end

  local current_line = vim.api.nvim_get_current_line()
  local contents = { current_line }
  local win = create_window()

  vim.api.nvim_win_set_option(win.win_id, "number", true)
  vim.api.nvim_buf_set_lines(win.bufnr, 0, #contents, false, contents)
  vim.api.nvim_buf_set_option(win.bufnr, "filetype", "sh")

  vim.api.nvim_buf_set_keymap(
    win.bufnr,
    "n",
    "<CR>",
    string.format("<Cmd>lua require('custom.teddy').submit(%d, %d) <CR>", win.bufnr, channel),
    { silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    win.bufnr,
    "n",
    "q",
    string.format("<Cmd>lua require('custom.teddy').close(%d) <CR>", win.bufnr),
    { silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    win.bufnr,
    "n",
    "<Esc>",
    string.format("<Cmd>lua require('custom.teddy').close(%d) <CR>", win.bufnr),
    { silent = true }
  )
end

function M.close(buf_id)
  vim.cmd(string.format("bd! %d", buf_id))
end

function M.submit(buf_id, channel_id)
  local terminate = vim.api.nvim_replace_termcodes("<C-c>", true, true, true)
  local current_line = vim.api.nvim_get_current_line()

  vim.notify("Executing " .. current_line)

  vim.api.nvim_chan_send(channel_id, terminate .. current_line .. "\n")
  M.close(buf_id)
end

vim.keymap.set({ "n", "t" }, "<A-e>", M.edit, { remap = true })

return M
