-- Named space sequences for .dot format encoding

--[[
  Author: Martin Eden
  Last mod.: 2026-07-27
]]

-- Imports:
local Ascii = request('Ascii')

local Spaces =
  {
    space = Ascii.space,
    newline = Ascii.newline,
    indent = Ascii.space .. Ascii.space,
  }

-- Export:
return Spaces

--[[
  2026-07-27
]]
