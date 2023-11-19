---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"

M.ui = {
  theme = "ayu_dark",
  theme_toggle = { "ayu_dark", "one_light" },

  hl_override = highlights.override,
  hl_add = highlights.add,

  changed_themes = {
    ayu_dark = {
      base_16 = {
        base00 = "#000005",
      }
    },
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
