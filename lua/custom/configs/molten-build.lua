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

local function activate()
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
              activate()
              return
            end
            notify(
              string.format("dependency installation failed with code %d: %s", _obj.code, _obj.stderr),
              vim.log.levels.WARN
            )
          end)
        end
        if num_checked == #deps and vim.tbl_isempty(not_installed) then
          activate()
        end
      end)
    )
  end
end)
