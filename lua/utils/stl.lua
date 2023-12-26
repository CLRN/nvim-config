local M = {}

---Get string representation of a string with highlight
---@param str? string sign symbol
---@param hl? string name of the highlight group
---@param restore? boolean restore highlight after the sign, default true
---@return string sign string representation of the sign with highlight
function M.hl(str, hl, restore)
  restore = restore == nil or restore
  -- Don't add highlight in tty to get a cleaner UI
  hl = vim.g.modern_ui and hl or ''
  return restore and table.concat({ '%#', hl, '#', str or '', '%*' })
    or table.concat({ '%#', hl, '#', str or '' })
end

---Make a winbar string clickable
---@param str string
---@param callback string
---@return string
function M.make_clickable(str, callback)
  return string.format('%%@%s@%s%%X', callback, str)
end

return M
