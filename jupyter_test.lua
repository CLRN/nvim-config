local M = {}

---@class Image
---@field id string

---@class JsonCellMetadata
---@field collapsed? boolean

---@class JsonCellStdOutput
---@field name string
---@field output_type string
---@field text string[]

---@class JsonCellResultOutput
---@field execution_count integer
---@field metadata JsonCellMetadata
---@field output_type string
---@field data table<string, string>

---@class JsonCell
---@field cell_type string
---@field execution_count integer
---@field metadata JsonCellMetadata
---@field source string[]
---@field outputs (JsonCellStdOutput | JsonCellResultOutput)[]

---@alias ExecutionState "ready"|"running"|"error"

---@class CellState
---@field begin_mark integer?
---@field output_marks integer[]
---@field images Image[]
---@field execution_state ExecutionState

---@class BufferState
---@field book { cells: JsonCell[] }
---@field cells table<integer, CellState>
---@field message_to_cell_idx table<string, integer>
---@field send? fun(string): string
---@field shutdown? fun(): nil

local jupyter = require "custom.jupyter_server"
local async = require "plenary.async"
local image = require "image"
local colors = require "baleia.nvim.colors"
local ansi = require "baleia.colors.ansi"
local locations = require "baleia.locations"
local styles = require "baleia.styles"
local text = require "baleia.text"

local ns_id = vim.api.nvim_create_namespace "jupyter"
local output_line_limit = 20

---@type table<ExecutionState, string>
local state_sign_map = {
  ["ready"] = "󰄳 ",
  ["error"] = " ",
  ["running"] = " ",
}

--- @param lines string[]
--- @param line_num integer
--- @return integer
local function set_output_text(lines, line_num)
  local styles_per_line = {}

  for _, location in ipairs(locations.extract(lines)) do
    styles_per_line[location.from.line] = location.style
  end

  local virt_lines = {}
  for idx, line in ipairs(text.strip_color_codes(lines)) do
    local style = styles_per_line[idx]
    if style then
      local name = styles.name("JupyterColors", style)
      local attributes = styles.attributes(style, colors.theme(ansi.NR_8))
      vim.api.nvim_set_hl(0, name, attributes)

      table.insert(virt_lines, { { line, { "Comment", name } } })
    else
      table.insert(virt_lines, { { line, "Comment" } })
    end
  end

  if #virt_lines > output_line_limit then
    virt_lines = vim.list_slice(virt_lines, #virt_lines - output_line_limit, #virt_lines)
  end

  local col_num = 0
  return vim.api.nvim_buf_set_extmark(vim.api.nvim_get_current_buf(), ns_id, line_num, col_num, {
    virt_lines = virt_lines,
    sign_text = "O",
  })
end

--- @param lines string[]
--- @param out string[]
local function parse_lines(lines, out)
  for _, src in ipairs(lines) do
    if src == "\n" then
      table.insert(out, "")
    else
      for _, p in ipairs(vim.split(src, "\n")) do
        if p ~= "" then
          table.insert(out, p)
        end
      end
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
      return { ext_mark = set_output_text(cell_output, line_num - 1) }
    end
  end,
  ["image/png"] = function(data, line_num)
    if data then
      local file = assert(io.open("image.png", "w"))

      file:write(require("b64").dec(data))
      file:close()

      local img = image.from_file("image.png", {
        window = vim.api.nvim_get_current_win(), -- optional, binds image to a window and its bounds
        buffer = vim.api.nvim_get_current_buf(), -- optional, binds image to a buffer (paired with window binding)
        with_virtual_padding = true, -- optional, pads vertically with extmarks
        x = 0,
        y = line_num,
      })

      img:render()
      return { image_id = img.id }
    end
  end,
}

---@type BufferState[]
local buffer_state = {}

--- @param jupyter_cell JsonCell
--- @param cell_idx integer
--- @param start_line integer
--- @param execution_state? ExecutionState
local function load_cell(jupyter_cell, cell_idx, start_line, execution_state)
  local bufnr = vim.api.nvim_get_current_buf()
  local cell = buffer_state[bufnr].cells[cell_idx]
  execution_state = execution_state or "ready"

  -- figure out if we already have this cell rendered, get last line, drop marks and images
  if cell and cell.begin_mark then
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, cell.begin_mark)
  end

  for _, mark_id in ipairs((cell or {}).output_marks or {}) do
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark_id)
  end

  for _, image_id in ipairs((cell or {}).images or {}) do
    image.clear(image_id)
  end

  -- find next cell
  local end_line = -1
  local next_cell = buffer_state[bufnr].cells[cell_idx + 1]
  if next_cell then
    local next_mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, next_cell.begin_mark, {})
    if next_mark then
      end_line = next_mark[1] - 1
    end
  end

  -- parse lines and insert code
  local contents = {}
  table.insert(contents, "# %%")
  parse_lines(jupyter_cell.source, contents)
  table.insert(contents, "")

  -- set lines to the buffer
  vim.api.nvim_buf_set_lines(0, start_line, end_line, false, contents)
  local text_line_num = start_line + #contents

  -- parse stdout, add empty line for each cell output and attach extmarks to it
  local output_marks = {}
  local images = {}
  for _, out in ipairs(jupyter_cell.outputs) do
    vim.api.nvim_buf_set_lines(0, text_line_num, text_line_num + 1, false, { "" })

    local text_out = mime_type_handlers["text/plain"](out.text, text_line_num)
    if text_out and text_out.ext_mark then
      table.insert(output_marks, text_out.ext_mark)
    end
    if text_out and text_out.image_id then
      table.insert(images, text_out.image_id)
    end

    for mime, data in pairs(out.data or {}) do
      local outputs = mime_type_handlers[mime](data, text_line_num)
      if outputs.ext_mark then
        table.insert(output_marks, outputs.ext_mark)
      end
    end

    text_line_num = text_line_num + 1
  end

  buffer_state[bufnr].cells[cell_idx] = {
    begin_mark = vim.api.nvim_buf_set_extmark(
      bufnr,
      ns_id,
      start_line,
      0,
      { sign_text = state_sign_map[execution_state] }
    ),
    output_marks = output_marks,
    images = images,
    execution_state = execution_state,
  }

  return text_line_num
end

--- @param state BufferState
local function render(state)
  local bufnr = vim.api.nvim_get_current_buf()

  -- clear buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

  local text_line_num = 0

  for cell_idx, cell in ipairs(state.book.cells) do
    text_line_num = text_line_num + load_cell(cell, cell_idx, text_line_num)
  end
end

-- @returns { cell_idx: integer, start_line: integer, stop_line: integer}
local function get_cell_under_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
  local start = 0
  local stop = -1
  local cell_idx = 0

  for idx, cell in ipairs(buffer_state[bufnr].cells) do
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, cell.begin_mark, {})
    local mark_line = mark[1]
    if mark_line > cursor[1] then
      stop = mark_line - 1
      break
    end
    start = mark_line
    cell_idx = idx
  end
  return { cell_idx = cell_idx, start_line = start, stop_line = stop }
end

--- @param bufnr integer
--- @param msg_id string
--- @param lines string[]
local function handle_jupyter_output(bufnr, msg_id, lines)
  local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
  local marks = buffer_state[bufnr].cells[cell_idx].output_marks

  if marks then
    local mark_id = marks[1]
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, mark_id, {})
    for _, line in ipairs(lines) do
      if line ~= "" then
        table.insert(buffer_state[bufnr].book.cells[cell_idx].outputs[1].text, line)
      end
    end

    local new_mark_id = set_output_text(buffer_state[bufnr].book.cells[cell_idx].outputs[1].text, mark[1])

    if mark_id ~= new_mark_id then
      vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark_id)
      buffer_state[bufnr].cells[cell_idx].output_marks = { new_mark_id }
    end
  end
end

function M.load()
  local bufnr = vim.api.nvim_get_current_buf()
  async.run(function()
    local jupyter_data = jupyter {
      on_kernel_status = function(status) end,
      on_cell_status = function(msg_id, status)
        local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
        if not cell_idx then
          return
        end
        local cell = buffer_state[bufnr].cells[cell_idx]
        local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, cell.begin_mark, {})

        if status == "running" then
          -- clear previous outputs
          buffer_state[bufnr].book.cells[cell_idx].outputs = { { name = "stdout", output_type = "stream", text = {} } }
        end

        load_cell(buffer_state[bufnr].book.cells[cell_idx], cell_idx, mark[1], status)
      end,
      on_error = function(msg_id, lines)
        handle_jupyter_output(bufnr, msg_id, lines)
      end,
      on_output = function(msg_id, text)
        handle_jupyter_output(bufnr, msg_id, vim.split(text, "\n"))
      end,
      on_display_data = function(msg_id, data)
        local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
        table.insert(buffer_state[bufnr].book.cells[cell_idx].outputs, data)
        local cell = buffer_state[bufnr].cells[cell_idx]
        local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, cell.begin_mark, {})
        load_cell(buffer_state[bufnr].book.cells[cell_idx], cell_idx, mark[1])
      end,
    }
    buffer_state[bufnr].send = jupyter_data.send
    buffer_state[bufnr].shutdown = jupyter_data.stop
  end)

  buffer_state[bufnr] = {
    book = vim.fn.json_decode(
      table.concat(vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false), "\n")
    ),
    cells = {},
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
  local img = api.from_file("image.png", {
    window = win, -- optional, binds image to a window and its bounds
    buffer = buf, -- optional, binds image to a buffer (paired with window binding)
    with_virtual_padding = true, -- optional, pads vertically with extmarks
    x = 1,
    y = 1,
    width = 100,
    height = 100,
  })

  img:render()

  -- vim.defer_fn(function()
  --   -- vim.api.nvim_win_close(win, true)
  --   vim.api.nvim_win_set_height(win, 2)
  -- end, 5000)
end

function M.execute_current_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cell = get_cell_under_cursor()

  -- +1 to skip cell comment "# %%"
  local lines = vim.api.nvim_buf_get_lines(bufnr, cell.start_line + 1, cell.stop_line, false)
  while #lines and lines[#lines] == "" do
    table.remove(lines, #lines)
  end

  -- jupyter stores end line in all lines except last
  for idx, line in ipairs(lines) do
    if idx ~= #lines then
      lines[idx] = line .. "\n"
    end
  end

  -- reset state and output, save code to the jupyter cells
  buffer_state[bufnr].book.cells[cell.cell_idx].source = lines
  load_cell(buffer_state[bufnr].book.cells[cell.cell_idx], cell.cell_idx, cell.start_line)

  local msg_id = buffer_state[bufnr].send(table.concat(lines, "\n"))
  buffer_state[bufnr].message_to_cell_idx[msg_id] = cell.cell_idx

  -- TODO: try to change jupyter server to work through async corotines and
  -- generate events right there without callbacks
end

function M.rerender_current_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cell = get_cell_under_cursor()
  load_cell(buffer_state[bufnr].book.cells[cell.cell_idx], cell.cell_idx, cell.start_line)
end

vim.keymap.set("n", "<leader>qq", function()
  M.load()
end, { remap = true })

vim.keymap.set("n", "<leader>qs", function()
  M.save()
end, { remap = true })

vim.keymap.set("n", "<leader>qr", function()
  M.rerender_current_cell()
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
