-- List of Lua VM control-flow instructions ( Lua 5.3 )

--[[
  Author: Martin Eden
  Last mod.: 2026-07-30
]]

local FlowOpcodes =
  {
    -- Terminal statements
    [1] = {
      'TAILCALL',
      'RETURN',
    },
    -- Jump to ( next + Arg[2] )
    [2] = 'JMP',
    -- Jumps to ( next, next + 1 )
    [3] = {
      'EQ',
      'LT',
      'LE',
      'TEST',
      'TESTSET',
    },
    -- Jumps to ( next, next + Arg[2] ) ( Arg[2] is signed )
    [4] = {
      'FORLOOP',
      'TFORLOOP',
    },
    -- Jump to ( next + Arg[2] )
    [5] = 'FORPREP',
  }

-- Export:
return FlowOpcodes

--[[
  2026-07-30
]]
