-- List of Lua VM control-flow instructions ( Lua 5.4 )

--[[
  Author: Martin Eden
  Last mod.: 2026-07-30
]]

local FlowOpcodes =
  {
    -- Terminals
    [1] = {
      'TAILCALL',
      'RETURN',
      'RETURN0',
      'RETURN1',
    },
    -- Jump to ( next + 1 )
    [2] = 'LFALSESKIP',
    -- Jump to ( next + Arg[1] ) ( Arg[1] is signed )
    [3] = 'JMP',
    -- Jump to ( next + Arg[2] )
    [4] = 'TFORPREP',
    -- Jumps to ( next, next + 1 )
    [5] = {
      'ADDI',
      'ADDK',
      'SUBK',
      'MULK',
      'MODK',
      'POWK',
      'DIVK',
      'IDIVK',
      'BANDK',
      'BORK',
      'BXORK',
      'SHRI',
      'SHLI',
      'ADD',
      'SUB',
      'MUL',
      'MOD',
      'POW',
      'DIV',
      'IDIV',
      'BAND',
      'BOR',
      'BXOR',
      'SHL',
      'SHR',
      'EQ',
      'LT',
      'LE',
      'EQK',
      'EQI',
      'LTI',
      'LEI',
      'GTI',
      'GEI',
      'TEST',
      'TESTSET',
    },
    -- Jumps to ( next, next - Arg[2] )
    [6] = {
      'FORLOOP',
      'TFORLOOP',
    },
    -- Jumps to ( next, next + Arg[2] + 1 )
    [7] = 'FORPREP',
  }

-- Export:
return FlowOpcodes

--[[
  2026-07-30
]]
