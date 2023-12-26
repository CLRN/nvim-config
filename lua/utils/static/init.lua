local M = {}

local langs_mt = {}
langs_mt.__index = langs_mt

---@param field string
---@return string[]
function langs_mt:list(field)
  local deduplist = {}
  local result = {}
  -- deduplication
  for _, info in pairs(self) do
    if type(info[field]) == 'string' then
      deduplist[info[field]] = true
    elseif type(info[field]) == 'table' then
      for _, name in pairs(info[field]) do
        deduplist[name] = true
      end
    end
  end
  for name, _ in pairs(deduplist) do
    table.insert(result, name)
  end
  return result
end

---@param field string
---@return table<string, string|string[]>
function langs_mt:map(field)
  local result = {}
  for lang, info in pairs(self) do
    result[lang] = info[field]
  end
  return result
end

M.langs = setmetatable({
  sh = {
    ft = 'sh',
    lsp_server = { 'bashls', 'efm' },
    dap = 'bashdb',
  },
  c = {
    ts = 'c',
    ft = 'c',
    lsp_server = 'clangd',
    dap = 'codelldb',
  },
  cpp = {
    ts = 'cpp',
    ft = 'cpp',
    lsp_server = 'clangd',
    dap = 'codelldb',
  },
  cuda = {
    ts = 'cuda',
    ft = 'cuda',
    lsp_server = 'clangd',
  },
  fish = {
    ts = 'fish',
    ft = 'fish',
    lsp_server = 'efm',
  },
  help = {
    ts = 'vimdoc',
    ft = 'help',
  },
  lua = {
    ts = 'lua',
    ft = 'lua',
    lsp_server = { 'lua_ls', 'efm' },
  },
  rust = {
    ts = 'rust',
    ft = 'rust',
    lsp_server = 'rust_analyzer',
  },
  make = {
    ts = 'make',
    ft = 'make',
  },
  markdown = {
    ts = {
      'markdown_inline',
      'markdown',
    },
    lsp_server = 'marksman',
  },
  python = {
    ts = 'python',
    ft = 'python',
    lsp_server = { 'jedi_language_server', 'efm' },
    dap = 'debugpy',
  },
  vim = {
    ts = 'vim',
    ft = 'vim',
    lsp_server = 'vimls',
  },
  tex = {
    ft = 'tex',
    ts = 'latex',
    lsp_server = 'texlab',
  },
  query = { -- Fix error `no parser for 'query' language` on `:InspectTree`
    ts = 'query',
  },
}, langs_mt)

local icons_mt = {}

function icons_mt:__index(key)
  for _, icons in pairs(self) do
    if icons[key] then
      return icons[key]
    end
  end
  return icons_mt[key]
end

---Flatten the layered icons table into a single type-icon table.
---@return table<string, string>
function icons_mt:flatten()
  local result = {}
  for _, icons in pairs(self) do
    for type, icon in pairs(icons) do
      result[type] = icon
    end
  end
  return result
end

if vim.g.modern_ui then
  M.box = require('utils.static._box')
  M.borders = require('utils.static._borders')
  M.icons = setmetatable(require('utils.static._icons'), icons_mt)
else
  M.box = require('utils.static._box_ascii')
  M.borders = require('utils.static._borders_ascii')
  M.icons = setmetatable(require('utils.static._icons_ascii'), icons_mt)
end

return M
