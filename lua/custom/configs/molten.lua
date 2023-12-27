if pcall(require, "image") then
  vim.g.molten_image_provider = "image.nvim"
end

vim.g.molten_enter_output_behavior = "open_and_enter"
vim.g.molten_output_win_max_height = 16
vim.g.molten_output_win_cover_gutter = false
vim.g.molten_output_win_border = { "", "", "", "" }
vim.g.molten_output_win_style = "minimal"
vim.g.molten_auto_open_output = false
vim.g.molten_output_show_more = true
vim.g.molten_virt_text_output = true
vim.g.molten_virt_lines_off_by_1 = true
vim.g.molten_virt_text_max_lines = 16
vim.g.molten_wrap_output = true

local deps = {
  "cairosvg",
  "ipykernel",
  "jupyter_client",
  "kaleido",
  "nbformat",
  "plotly",
  "pnglatex",
  "pynvim",
  "pyperclip",
  "jupyter",
  "ipywidgets",
}

---Shows a notification from molten
---@param msg string Content of the notification to show to the user.
---@param level integer|nil One of the values from |vim.log.levels|.
---@param opts table|nil Optional parameters. Unused by default.
---@return nil
local function notify(msg, level, opts)
  vim.schedule(function()
    vim.notify("[Molten] " .. msg, level, opts)
  end)
end

local num_checked = 0
local not_installed = {}
vim.schedule(function()
  for _, pkg in ipairs(deps) do
    vim.system(
      { "pip", "show", pkg },
      {},
      vim.schedule_wrap(function(obj)
        if obj.code ~= 0 then
          table.insert(not_installed, pkg)
          notify(string.format("python dependency %s not found", pkg), vim.log.levels.WARN)
        end
        num_checked = num_checked + 1
        if num_checked == #deps and not vim.tbl_isempty(not_installed) then
          if not vim.env.VIRTUAL_ENV then
            notify("start nvim in a venv to auto-install python dependencies", vim.log.levels.WARN)
            return
          end
          notify "auto-install python dependencies..."
          vim.system({ "pip", "install", unpack(not_installed) }, {}, function(_obj)
            if _obj.code == 0 then
              notify "all python dependencies satisfied"
              return
            end
            notify(
              string.format("dependency installation failed with code %d: %s", _obj.code, _obj.stderr),
              vim.log.levels.WARN
            )
          end)
        end
      end)
    )
  end
end)

---Send code cell to molten
---@param cell code_cell_t
---@return nil
local function send(cell)
  local range = cell.range
  vim.fn.MoltenEvaluateRange(range.from[1] + 1, range.to[1])
end

---Check if two ranges are overlapped
---@param r1 code_range_t
---@param r2 code_range_t
---@return boolean
local function is_overlapped(r1, r2)
  return r1.from[1] <= r2.to[1] and r2.from[1] <= r1.to[1]
end

---Get the overlap between two (line) ranges
---@param r1 code_range_t
---@param r2 code_range_t
---@return code_range_t?
local function get_overlap(r1, r2)
  if is_overlapped(r1, r2) then
    return {
      from = { math.max(r1.from[1], r2.from[1]), 0 },
      to = { math.min(r1.to[1], r2.to[1]), 0 },
    }
  end
end

---Extract code cells that overlap the given range,
---removes cells with a language that's in the ignore list
---@param lang string
---@param code_chunks table<string, code_cell_t>
---@param range code_range_t
---@param partial boolean?
---@return code_cell_t[]
local function extract_cells(lang, code_chunks, range, partial)
  local chunks = {}

  if partial then
    for _, chunk in ipairs(code_chunks[lang]) do
      local overlap = get_overlap(chunk.range, range)
      if overlap then
        if vim.deep_equal(overlap, chunk.range) then -- full overlap
          table.insert(chunks, chunk)
        else -- partial overlap
          local text = {}
          local lnum_start = overlap.from[1] - chunk.range.from[1] + 1
          local lnum_end = lnum_start + overlap.to[1] - overlap.from[1]
          for i = lnum_start, lnum_end do
            table.insert(text, chunk.text[i])
          end
          table.insert(
            chunks,
            vim.tbl_extend("force", chunk, {
              text = text,
              range = overlap,
            })
          )
        end
      end
    end
  else
    for _, chunk in ipairs(code_chunks[lang]) do
      if is_overlapped(chunk.range, range) then
        table.insert(chunks, chunk)
      end
    end
  end

  return chunks
end

local otk

---@type table<string, true>
local not_runnable = {
  markdown = true,
  markdown_inline = true,
  yaml = true,
}

---Find valid language under cursor that can be sent to REPL
---@return string?
local function get_valid_repl_lang()
  local lang = otk.get_current_language_context()
  if not lang or not_runnable[lang] then
    return
  end
  return lang
end

---Run code for the current language that overlap the given range
---
---Code are run in chunks (cells) , i.e. the whole chunk will be sent to
---REPL even when there are only partial overlap between the chunk and `range`
---@param range code_range_t a range, for with any overlapping code cells are run
---@return nil
local function run_cell(range)
  local buf = vim.api.nvim_get_current_buf()
  local lang = get_valid_repl_lang() or "python"

  otk.sync_raft(buf)
  local otk_buf_info = otk._otters_attached[buf]
  if not otk_buf_info then
    notify("code runner not initialized for buffer " .. buf, vim.log.levels.WARN)
    return
  end

  local filtered = extract_cells(lang, otk_buf_info.code_chunks, range)
  if #filtered == 0 then
    notify("no code found for " .. lang, vim.log.levels.WARN)
    return
  end
  for _, chunk in ipairs(filtered) do
    send(chunk)
  end
end

---Run current cell
---@return nil
local function run_cell_current()
  local y = vim.api.nvim_win_get_cursor(0)[1] - 1
  local r = { y, 0 }
  local range = { from = r, to = r }
  run_cell(range)
end

---Run current cell and all above
---@return nil
local function run_cell_above()
  local y = vim.api.nvim_win_get_cursor(0)[1] - 1
  local range = { from = { 0, 0 }, to = { y, 0 } }
  run_cell(range)
end

---Run current cell and all below
---@return nil
local function run_cell_below()
  local y = vim.api.nvim_win_get_cursor(0)[1] - 1
  local range = { from = { y, 0 }, to = { math.huge, 0 } }
  run_cell(range)
end

---Run current line of code
---@return nil
local function run_line()
  local lang = get_valid_repl_lang()
  if not lang then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)

  ---@type code_cell_t
  local cell = {
    lang = lang,
    range = { from = { pos[1] - 1, 0 }, to = { pos[1], 0 } },
    text = vim.api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false),
  }

  send(cell)
end

---Run code in range `range`
---
---Code are run in lines, i.e. only code lines in `range` will be sent to REPL,
---if there is a partial overlap between `range` and a code chunk,
---only the lines inside `range` will be run
---@param range code_range_t
---@return nil
local function run_range(range)
  local buf = vim.api.nvim_get_current_buf()
  local lang = get_valid_repl_lang() or "python"

  otk.sync_raft(buf)
  local otk_buf_info = otk._otters_attached[buf]
  if not otk_buf_info then
    notify("code runner not initialized for buffer " .. buf, vim.log.levels.WARN)
    return
  end

  local filtered = extract_cells(lang, otk_buf_info.code_chunks, range, true)
  if #filtered == 0 then
    notify("no code found for " .. lang, vim.log.levels.WARN)
    return
  end

  for _, chunk in ipairs(filtered) do
    send(chunk)
  end
end

---Run code in previous visual selection
---@return nil
local function run_visual()
  local vstart = vim.fn.getpos "'<"
  local vend = vim.fn.getpos "'>"
  run_range {
    from = { vstart[2] - 1, 0 },
    to = { vend[2], 0 },
  }
end

---Run code covered by operator
---@return nil
local function run_operator()
  vim.opt.opfunc = "v:lua._molten_nb_run_opfunc"
  vim.api.nvim_feedkeys("g@", "n", false)
end

---@param _ 'line'|'char'|'block' operator type, ignored
---@return nil
function _G._molten_nb_run_opfunc(_)
  local ostart = vim.fn.getpos "'["
  local oend = vim.fn.getpos "']"
  run_range {
    from = { ostart[2] - 1, 0 },
    to = { oend[2], 0 },
  }
end

---Set buffer-local keymaps and commands
---@param buf integer? buffer handler, defaults to current buffer
---@return nil
local function setup_buf_keymaps_and_commands(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local ft = vim.bo[buf].ft
  if ft ~= "markdown" and ft ~= "python" then
    return
  end

  vim.api.nvim_create_user_command(
    "MoltenHideCellHl",
    "hi! clear MoltenCell",
    { desc = "Hide the current code cell highlight in molten." }
  )
  vim.api.nvim_create_user_command(
    "MoltenShowCellHl",
    "hi! link MoltenCell CursorLine",
    { desc = "Show the current code cell highlight in molten." }
  )

  vim.keymap.set("n", "<C-c>", vim.cmd.MoltenInterrupt, { buffer = buf })
  vim.keymap.set("n", "<C-k>", function()
    vim.cmd.MoltenEnterOutput { mods = { noautocmd = true } }
    if vim.bo.ft == "molten_output" then
      vim.keymap.set("n", "<C-l>", "<C-w>c", { buffer = true })
    end
  end, { buffer = buf })

  local otk_ok
  otk_ok, otk = pcall(require, "otter.keeper")
  -- Use otter to recognized codeblocks in markdown files,
  -- so we can run current codeblock directly without selection
  -- using `<CR>`, and other good stuffs
  -- stylua: ignore start
  if ft == 'markdown' and otk_ok then
    vim.api.nvim_buf_create_user_command(buf, 'MoltenNotebookRunLine', run_line, {})
    vim.api.nvim_buf_create_user_command(buf, 'MoltenNotebookRunCellAbove', run_cell_above, {})
    vim.api.nvim_buf_create_user_command(buf, 'MoltenNotebookRunCellBelow', run_cell_below, {})
    vim.api.nvim_buf_create_user_command(buf, 'MoltenNotebookRunCellCurrent', run_cell_current, {})
    vim.api.nvim_buf_create_user_command(buf, 'MoltenNotebookRunVisual', run_visual, { range = true })
    vim.api.nvim_buf_create_user_command(buf, 'MoltenNotebookRunOperator', run_operator, {})
    vim.keymap.set('n', '<LocalLeader><LocalLeader>', run_operator, { buffer = buf })
    vim.keymap.set('n', '<LocalLeader>k', run_cell_above, { buffer = buf })
    vim.keymap.set('n', '<LocalLeader>j', run_cell_below, { buffer = buf })
    vim.keymap.set('n', '<CR>', run_cell_current, { buffer = buf })
    vim.keymap.set('x', '<CR>', ':<C-u>MoltenNotebookRunVisual<CR>', { buffer = buf })
  else -- ft == 'python' or otter.keeper not found
    vim.keymap.set('n', '<LocalLeader><LocalLeader>', vim.cmd.MoltenEvaluateOperator, { buffer = buf })
    vim.keymap.set('n', '<CR>', '<Cmd>MoltenReevaluateCell<CR>', { buffer = buf })
    vim.keymap.set('x', '<CR>', ':<C-u>MoltenEvaluateVisual<CR>', { buffer = buf })
  end
  -- stylua: ignore end
end

local groupid = vim.api.nvim_create_augroup("MoltenSetup", {})
vim.api.nvim_create_autocmd("User", {
  group = groupid,
  desc = "Set buffer-local keymaps and commands for molten.",
  pattern = "MoltenInitPost",
  callback = function(info)
    setup_buf_keymaps_and_commands(info.buf)
  end,
})

---Set default highlight groups for headlines.nvim
---@return nil
local function set_default_hlgroups()
  local hl = require "utils.hl"
  hl.set(0, "MoltenCell", {}) -- Hide cell highlight by default
  hl.set(0, "MoltenOutputWin", { link = "Comment" })
  hl.set(0, "MoltenOutputWinNC", { link = "Comment" })
end
set_default_hlgroups()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = groupid,
  desc = "Set default highlight groups for headlines.nvim.",
  callback = set_default_hlgroups,
})

