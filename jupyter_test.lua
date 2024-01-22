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
---@field code string[]
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
local log_buf = vim.api.nvim_create_buf(false, true)
local log_pos = 0
local augroup = vim.api.nvim_create_augroup("Jupyter", { clear = true })

--- log stuff
--- @param msg string|table
local function log(msg)
  if type(msg) ~= "string" then
    local line = vim.inspect(msg, { newline = "", indent = "  " })
    vim.api.nvim_buf_set_lines(log_buf, log_pos, log_pos + 1, false, { line })
  else
    vim.api.nvim_buf_set_lines(log_buf, log_pos, log_pos + 1, false, { msg })
  end
  log_pos = log_pos + 1
end

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
  local mark_id = vim.api.nvim_buf_set_extmark(vim.api.nvim_get_current_buf(), ns_id, line_num, col_num, {
    virt_lines = virt_lines,
    sign_text = "O",
  })
  log(string.format("set %d lines of output to line %d with mark id: %d", #lines, line_num, mark_id))
  return mark_id
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

      log(string.format("rendering image %s at %d", img.id, line_num))
      img:render()
      -- vim.defer_fn(function() end, 500)
      return { image_id = img.id }
    end
  end,
}

---@type BufferState[]
local buffer_state = {}

---gets code blocklocation for a cell
---@param cell_idx integer
---@return integer, integer
local function get_code_location(cell_idx)
  local bufnr = vim.api.nvim_get_current_buf()
  local cell = buffer_state[bufnr].cells[cell_idx]
  local begin = 0
  local end_ = -1

  if not cell then
    return begin, end_
  end

  if cell.begin_mark then
    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, cell.begin_mark, {})
    begin = mark[1]
  elseif cell_idx > 1 then
    -- figure out from previous cell
    local prev_begin, prev_end = get_code_location(cell_idx - 1)
    begin = prev_end + 1

    log(string.format("detected begin for %d from prev cell %d -> %d", cell_idx, prev_begin, prev_end))
  end

  if buffer_state[bufnr].cells[cell_idx + 1] then
    -- figure out from next cell
    local next_begin, next_end = get_code_location(cell_idx + 1)
    end_ = next_begin - 2
    log(string.format("detected end for %d from next cell %d -> %d", cell_idx, next_begin, next_end))
  else
    end_ = begin + #buffer_state[bufnr].cells[cell_idx].code
  end

  log(string.format("got cell %d position %d -> %d", cell_idx, begin, end_))
  return begin, end_
end

---@param cell_idx integer
local function clear_cell_output(cell_idx)
  local bufnr = vim.api.nvim_get_current_buf()
  local cell = buffer_state[bufnr].cells[cell_idx]

  for _, mark_id in ipairs((cell or {}).output_marks or {}) do
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark_id)
  end

  for _, image_id in ipairs((cell or {}).images or {}) do
    image.clear(image_id)
  end

  cell.output_marks = {}
  cell.images = {}
end

---parse stdout, add empty line for each cell output and attach extmarks to it
---@param cell_idx integer
local function render_output(cell_idx)
  local bufnr = vim.api.nvim_get_current_buf()
  local output_marks = {}
  local images = {}

  clear_cell_output(cell_idx)

  local _, line = get_code_location(cell_idx)

  for _, out in ipairs(buffer_state[bufnr].book.cells[cell_idx].outputs or {}) do
    vim.api.nvim_buf_set_lines(0, line, line + 1, false, { "" })

    local text_out = mime_type_handlers["text/plain"](out.text, line)
    if text_out and text_out.ext_mark then
      table.insert(output_marks, text_out.ext_mark)
    end
    if text_out and text_out.image_id then
      table.insert(images, text_out.image_id)
    end

    for mime, data in pairs(out.data or {}) do
      local outputs = mime_type_handlers[mime](data, line)
      if outputs.ext_mark then
        table.insert(output_marks, outputs.ext_mark)
      end
      line = line + 1
    end
  end

  buffer_state[bufnr].cells[cell_idx].output_marks = output_marks
  buffer_state[bufnr].cells[cell_idx].images = images
end

---reads jupyter code cell and returns lines
---@param cell_idx integer
---@return string[]
local function parse_jupyter_cell_code(cell_idx)
  local bufnr = vim.api.nvim_get_current_buf()
  -- parse lines and insert code
  local contents = {}
  table.insert(contents, "# %%")
  parse_lines(buffer_state[bufnr].book.cells[cell_idx].source, contents)
  table.insert(contents, "")
  return contents
end

---renders code block of a cell
---@param cell_idx integer
local function render_code(cell_idx)
  local bufnr = vim.api.nvim_get_current_buf()
  buffer_state[bufnr].cells[cell_idx].code = parse_jupyter_cell_code(cell_idx)

  local begin, end_ = get_code_location(cell_idx)

  -- set source code lines to the buffer
  vim.api.nvim_buf_set_lines(bufnr, begin, end_, false, buffer_state[bufnr].cells[cell_idx].code)

  -- only after we set the source code we can set begin/end marks
  local cell = buffer_state[bufnr].cells[cell_idx]

  local begin_mark =
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, begin, 0, { sign_text = state_sign_map[cell.execution_state] })

  -- make sure we delete the old one
  if cell.begin_mark and cell.begin_mark ~= begin_mark then
    log("deleting old extmark " .. cell.begin_mark)
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, cell.begin_mark)
  end

  buffer_state[bufnr].cells[cell_idx].begin_mark = begin_mark

  log(
    string.format(
      "cell %d, added %d source lines from %d to %d, outputs: %d",
      cell_idx,
      #contents,
      begin,
      end_,
      #buffer_state[bufnr].book.cells[cell_idx].outputs
    )
  )
  log(buffer_state[bufnr].cells[cell_idx])
end

--- @param cell_idx integer
--- @param execution_state? ExecutionState
local function load_cell(cell_idx, execution_state)
  local bufnr = vim.api.nvim_get_current_buf()
  buffer_state[bufnr].cells[cell_idx] = { output_marks = {}, images = {}, execution_state = execution_state or "ready" }

  render_code(cell_idx)
  render_output(cell_idx)
  log(buffer_state[bufnr].cells[cell_idx])
end

--- @param state BufferState
local function render(state)
  local bufnr = vim.api.nvim_get_current_buf()

  -- clear buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

  for cell_idx, _ in ipairs(state.book.cells) do
    load_cell(cell_idx)
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

--- @param msg_id string
--- @param lines string[]
--- @param output_type "error"|"stdout"
local function handle_jupyter_output(msg_id, lines, output_type)
  local bufnr = vim.api.nvim_get_current_buf()
  local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
  if not cell_idx then
    return
  end

  if not buffer_state[bufnr].book.cells[cell_idx].outputs[1] then
    log(string.format("creating new output cell for cell id %d", cell_idx))
    buffer_state[bufnr].book.cells[cell_idx].outputs = { { name = "stdout", output_type = "stream", text = {} } }
    render_output(cell_idx)
  end

  local marks = buffer_state[bufnr].cells[cell_idx].output_marks

  local out_text = buffer_state[bufnr].book.cells[cell_idx].outputs[1].text
  for _, line in ipairs(lines) do
    if line ~= "" then
      table.insert(out_text, line)
    end
  end

  local mark_id = marks[1]
  local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, mark_id, {})
  local new_mark_id = set_output_text(out_text, mark[1])

  log(
    string.format("set %d lines of output to cell %d at line %d using mark %d", #out_text, cell_idx, mark[1], mark_id)
  )

  if mark_id ~= new_mark_id then
    log(string.format("deleting old output mark for cell id %d, new mark: %d", cell_idx, mark_id, new_mark_id))
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark_id)
    buffer_state[bufnr].cells[cell_idx].output_marks = { new_mark_id }
  end
end

function M.load()
  local bufnr = vim.api.nvim_get_current_buf()

  async.run(function()
    local jupyter_data = jupyter {
      on_kernel_status = function(status)
        log(string.format("kernel status: %s", status))
      end,
      on_cell_status = function(msg_id, status)
        local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
        if not cell_idx then
          return
        end
        log(string.format("cell %d status: %s", cell_idx, status))
        render_output(cell_idx)
      end,
      on_error = function(msg_id, lines)
        handle_jupyter_output(msg_id, lines, "error")
      end,
      on_output = function(msg_id, text)
        handle_jupyter_output(msg_id, vim.split(text, "\n"), "stdout")
      end,
      on_display_data = function(msg_id, data)
        local cell_idx = buffer_state[bufnr].message_to_cell_idx[msg_id]
        table.insert(buffer_state[bufnr].book.cells[cell_idx].outputs, data)
        render_output(cell_idx)
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

function M.clear()
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
  buffer_state[bufnr].book.cells[cell.cell_idx].outputs = {}

  -- sync the state with update code
  buffer_state[bufnr].cells[cell.cell_idx].code = parse_jupyter_cell_code(cell.cell_idx)

  clear_cell_output(cell.cell_idx)

  local msg_id = buffer_state[bufnr].send(table.concat(lines, "\n"))
  buffer_state[bufnr].message_to_cell_idx[msg_id] = cell.cell_idx
end

function M.rerender_current_cell()
  local cell = get_cell_under_cursor()
  load_cell(cell.cell_idx)
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
  M.clear()
end, { remap = true })

vim.keymap.set("n", "<leader>qx", function()
  M.execute_current_cell()
end, { remap = true })

vim.keymap.set("n", "<leader>qw", function()
  M.win()
end, { remap = true })

vim.keymap.set("n", "<leader>ql", function()
  local lines = vim.api.nvim_buf_get_lines(log_buf, 0, -1, false)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end, { remap = true })

vim.api.nvim_create_autocmd({ "BufLeave", "VimLeave" }, {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if buffer_state[bufnr] and buffer_state[bufnr].shutdown then
      buffer_state[bufnr].shutdown()
      table.remove(buffer_state, bufnr)
    end
  end,
  group = augroup,
})

return M
