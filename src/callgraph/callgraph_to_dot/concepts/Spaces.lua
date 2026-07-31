-- Named available space characters for .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-31
]]

-- Imports:
local Ascii = request('^.^.^.concepts.Ascii')

local Spaces =
  {
    space = Ascii.space,
    tab = Ascii.tab,
    newline = Ascii.newline,
  }

-- Export:
return Spaces

--[[
  2026-07-27
  2026-07-29
]]
