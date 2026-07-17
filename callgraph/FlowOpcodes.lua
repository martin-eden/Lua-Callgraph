-- Return table with control flow-changing named opcode values

--[[
  Author: Martin Eden
  Last mod.: 2026-07-17
]]

-- Lua 5.5 opcode names from "luac -l"

local FlowOpcodes =
  {
    return_nothing = 'RETURN0',
    return_item = 'RETURN1',
    return_sequence = 'RETURN',

    jump = 'JMP',

    equal_reg = 'EQ',
    equal_const_table = 'EQK',
    less_than = 'LT',
    less_or_equal = 'LE',

    equal_imm = 'EQI',
    less_than_imm = 'LTI',
    less_or_equal_imm = 'LEI',
    greater_than_imm = 'GTI',
    greater_or_equal_imm = 'GEI',

    set_false_and_skip = 'LFALSESKIP',

    if_neq_then_skip = 'TEST',
    if_neq_then_skip_else_set = 'TESTSET',

    check_numeric_loop = 'FORPREP',
    check_generic_loop = 'TFORPREP',

    numeric_loop_back = 'FORLOOP',
    generic_loop_back = 'TFORLOOP',
  }

-- Export:
return FlowOpcodes

--[[
  2026-07-15
  2026-07-17
]]
