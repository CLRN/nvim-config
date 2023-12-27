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
-- vim.g.molten_virt_lines_off_by_1 = true
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
  notify "checking dependencies..."
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
        elseif num_checked == #deps and vim.tbl_isempty(not_installed) then
          notify "all python dependencies satisfied"
        end
      end)
    )
  end
end)

---@param buf integer? buffer handler, defaults to current buffer
---@return nil
local function setup_buf_keymaps_and_commands(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local nn = require "notebook-navigator"
  vim.keymap.set("n", "<C-c>", vim.cmd.MoltenInterrupt, { buffer = buf })
  vim.keymap.set("n", "<leader>mi", vim.cmd.MoltenInit, { buffer = buf, desc = "Init Molten" })
  vim.keymap.set("n", "<leader>mr", vim.cmd.MoltenRestart, { buffer = buf, desc = "Restart Molten" })
  vim.keymap.set("n", "<C-k>", function()
    vim.cmd.MoltenEnterOutput { mods = { noautocmd = true } }
    if vim.bo.ft == "molten_output" then
      vim.keymap.set("n", "<C-l>", "<C-w>c", { buffer = true })
    end
  end, { buffer = buf })
end

local groupid = vim.api.nvim_create_augroup("MoltenSetup", {})
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = groupid,
  pattern = "*.ipynb",
  callback = function(info)
    setup_buf_keymaps_and_commands(info.buf)
  end,
})
