local M = {}

local jupyter = require "custom.jupyter_server"
local async = require "plenary.async"

local ns_id = vim.api.nvim_create_namespace "jupyter"

local function add_virtual_text(lines, line_num)
  local virt_lines = {}
  for _, line in ipairs(lines) do
    table.insert(virt_lines, { { line, "" } })
  end

  local col_num = 0
  return vim.api.nvim_buf_set_extmark(vim.api.nvim_get_current_buf(), ns_id, line_num, col_num, {
    virt_lines = virt_lines,
  })
end

local function parse_lines(lines, out)
  for _, src in ipairs(lines) do
    if src:sub(-1) == "\n" then
      table.insert(out, src:sub(1, -2))
    else
      table.insert(out, src)
    end
  end
end

local mime_type_handlers = {
  ["text/plain"] = function(data, line_num)
    if data then
      local cell_output = {}
      if type(data) == "table" then
        parse_lines(data, cell_output)
      else
        parse_lines(vim.split(data, "\n"), cell_output)
      end
      return { ext_mark = add_virtual_text(cell_output, line_num - 1) }
    end
  end,
  ["image/png"] = function(data, line_num)
    if data then
      local file = assert(io.open("image.png", "w"))

      file:write(require("b64").dec(data))
      file:close()

      local api = require "image"
      local image = api.from_file("image.png", {
        window = vim.api.nvim_get_current_win(), -- optional, binds image to a window and its bounds
        buffer = vim.api.nvim_get_current_buf(), -- optional, binds image to a buffer (paired with window binding)
        with_virtual_padding = true, -- optional, pads vertically with extmarks
        x = 0,
        y = line_num - 1,
      })

      image:render()
      return { image_id = image.id }
    end
  end,
}

local buffer_state = {}

local function render(state)
  local bufnr = vim.api.nvim_get_current_buf()

  -- clear buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

  local text_line_num = 0
  local cell_lines = {}
  for cell_idx, cell in ipairs(state.book.cells) do
    -- parse lines and insert code
    local contents = {}
    table.insert(contents, "# %%")
    parse_lines(cell.source, contents)
    table.insert(contents, "")

    -- remember cell begin via ext mark
    table.insert(cell_lines, text_line_num)

    -- set lines to the buffer
    vim.api.nvim_buf_set_lines(0, text_line_num, -1, false, contents)
    text_line_num = text_line_num + #contents

    -- parse stdout, add empty line for each cell output and attach extmarks to it
    local output_marks = {}
    for _, out in ipairs(cell.outputs) do
      vim.api.nvim_buf_set_lines(0, text_line_num, -1, false, { "" })

      local text_out = mime_type_handlers["text/plain"](out.text, text_line_num)
      if text_out and text_out.ext_mark then
        table.insert(output_marks, text_out.ext_mark)
      end

      for mime, data in pairs(out.data or {}) do
        local outputs = mime_type_handlers[mime](data, text_line_num)
        if outputs.ext_mark then
          table.insert(output_marks, outputs.ext_mark)
        end
      end

      text_line_num = text_line_num + 1
    end

    state.output_marks[cell_idx] = output_marks
  end

  for _, line in ipairs(cell_lines) do
    local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, { sign_text = "▶" })
    table.insert(state.cell_marks, mark_id)
  end

  vim.print(state.output_marks)

  -- vim.api.nvim_buf_set_option(0, "filetype", "python")
end

local function handle_jupyter_output(bufnr, msg_id, lines)
  local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
  local marks = buffer_state[bufnr].output_marks[cell_idx]
  if marks then
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, marks[1], {})
    buffer_state[bufnr].output_marks[cell_idx] = { add_virtual_text(lines, mark[1]) }
  end
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark)
  end
end

function M.load()
  local bufnr = vim.api.nvim_get_current_buf()
  async.run(function()
    local jupyter_data = jupyter {
      on_kernel_status = function(status)
        print("kernel", status)
      end,
      on_cell_status = function(msg_id, status)
        local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
        local mark_id = buffer_state[bufnr].cell_marks[cell_idx]
        local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, mark_id, {})
        local sign = "▶"
        if status == "running" then
          sign = "."
        elseif status == "error" then
          sign = "X"
        end
        buffer_state[bufnr].cell_marks[cell_idx] =
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, mark[1], 0, { sign_text = sign })
      end,
      on_error = function(msg_id, lines)
        handle_jupyter_output(bufnr, msg_id, lines)
      end,
      on_output = function(msg_id, text)
        handle_jupyter_output(bufnr, msg_id, vim.split(text, "\n"))
      end,
    }
    buffer_state[bufnr].send = jupyter_data.send
    buffer_state[bufnr].shutdown = jupyter_data.stop
  end)

  buffer_state[bufnr] = {
    book = vim.fn.json_decode(
      table.concat(vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false), "\n")
    ),
    cell_marks = {},
    output_marks = {},
    message_to_cell_idx = {},
  }

  render(buffer_state[bufnr])
end

function M.save()
  local bufnr = vim.api.nvim_get_current_buf()

  local data = vim.fn.json_encode(buffer_state[bufnr].book)

  local file = assert(io.open(vim.api.nvim_buf_get_name(bufnr), "w"))

  file:write(data)
  file:close()
end

function M.show()
  local api = require "image"
  for _, img in ipairs(api.get_images()) do
    img:render()
  end
end

function M.hide()
  local api = require "image"
  for _, img in ipairs(api.get_images()) do
    img:clear()
  end
end

function M.win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "test", "text" })
  local opts = { relative = "win", width = 10, height = 10, bufpos = { 10, 10 }, style = "minimal" }
  local win = vim.api.nvim_open_win(buf, false, opts)
  vim.api.nvim_set_option_value("winhl", "Normal:MyHighlight", { win = win })

  local api = require "image"
  local image = api.from_file("image.png", {
    window = win, -- optional, binds image to a window and its bounds
    buffer = buf, -- optional, binds image to a buffer (paired with window binding)
    with_virtual_padding = true, -- optional, pads vertically with extmarks
    x = 1,
    y = 1,
    width = 100,
    height = 100,
  })

  image:render()

  -- vim.defer_fn(function()
  --   -- vim.api.nvim_win_close(win, true)
  --   vim.api.nvim_win_set_height(win, 2)
  -- end, 5000)
end

function M.execute_current_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
  local start = 0
  local stop = -1
  local cell_idx = 0

  for idx, mark_id in ipairs(buffer_state[bufnr].cell_marks) do
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, mark_id, {})
    local mark_line = mark[1]
    if mark_line > cursor[1] then
      stop = mark_line - 1
      break
    end
    start = mark_line
    cell_idx = idx
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start, stop, false)
  local msg_id = buffer_state[bufnr].send(table.concat(lines, "\n"))
  buffer_state[bufnr].message_to_cell_idx[msg_id] = cell_idx

  -- TODO: try to change jupyter server to work through async corotines and
  -- generate events right there without callbacks
end

vim.keymap.set("n", "<leader>qq", function()
  M.load()
end, { remap = true })

vim.keymap.set("n", "<leader>qs", function()
  M.save()
end, { remap = true })

vim.keymap.set("n", "<leader>qr", function()
  M.show()
end, { remap = true })

vim.keymap.set("n", "<leader>qc", function()
  M.hide()
end, { remap = true })

vim.keymap.set("n", "<leader>qx", function()
  M.execute_current_cell()
end, { remap = true })

vim.keymap.set("n", "<leader>qw", function()
  M.win()
end, { remap = true })

return M
