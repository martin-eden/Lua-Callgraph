-- Item delimiters used for encoding to .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-29
]]

-- Imports:
local Spaces = request('^.^.concepts.Spaces')

local Delimiters =
  {
    line_item_separator = Spaces.space,
    line_separator = Spaces.newline,
  }

-- Export:
return Delimiters

--[[
  2026-07-29
]]
