-- Named available space characters for .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-08-07
]]

-- Imports:
local AsciiChars = request('!.concepts.Ascii.Chars')

local Spaces =
  {
    space = AsciiChars.space,
    tab = AsciiChars.tab,
    newline = AsciiChars.newline,
  }

-- Export:
return Spaces

--[[
  2026-07-27
  2026-07-29
]]
