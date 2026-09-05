-- Quote string for .dot

--[[
  Author: Martin Eden
  Last mod.: 2026-09-05
]]

local quote = request('Syntels').quote

-- Export:
return
  function(str)
    return quote .. str .. quote
  end

--[[
  2026 #
]]
