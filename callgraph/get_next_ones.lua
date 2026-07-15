-- Return table with possible next instructions indices. Lua 5.5

--[[
  Author: Martin Eden
  Last mod.: 2026-07-15
]]

-- Core of this ship

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

local Terminators =
  {
    FlowOpcodes.return_nothing,
    FlowOpcodes.return_item,
    FlowOpcodes.return_sequence,
  }

local Jumpers =
  {
    FlowOpcodes.jump,
  }

local Skippers =
  {
    FlowOpcodes.equal_reg,
    FlowOpcodes.equal_const_table,
    FlowOpcodes.less_than,
    FlowOpcodes.less_or_equal,
    FlowOpcodes.equal_imm,
    FlowOpcodes.less_than_imm,
    FlowOpcodes.less_or_equal_imm,
    FlowOpcodes.greater_than_imm,
    FlowOpcodes.greater_or_equal_imm,
    FlowOpcodes.set_false_and_skip,
    FlowOpcodes.if_neq_then_skip,
    FlowOpcodes.if_neq_then_skip_else_set,
  }

local ForwardJumpers =
  {
    FlowOpcodes.check_generic_loop,
  }

local ForwardJumpersAndSkippers =
  {
    FlowOpcodes.check_numeric_loop,
  }

local BackwardJumpers =
  {
    FlowOpcodes.numeric_loop_back,
    FlowOpcodes.generic_loop_back,
  }

local get_next_ones
do
  local Terminators_Map
  local Jumpers_Map
  local Skippers_Map
  local ForwardJumpers_Map
  local ForwardJumpersAndSkippers_Map
  local BackwardJumpers_Map
  do
    local map_values = request('!.table.map_values')

    Terminators_Map = map_values(Terminators)
    Jumpers_Map = map_values(Jumpers)
    Skippers_Map = map_values(Skippers)
    ForwardJumpers_Map = map_values(ForwardJumpers)
    ForwardJumpersAndSkippers_Map = map_values(ForwardJumpersAndSkippers)
    BackwardJumpers_Map = map_values(BackwardJumpers)
  end

  local add_to_list = request('!.concepts.list.add_item')

  get_next_ones =
    function(instruction_index, Instruction)
      local NextOnes = { }

      local opcode = Instruction[1]
      local next_instruction_index = instruction_index +  1

      if Terminators_Map[opcode] then
        ;
      elseif Jumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[2])
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif Skippers_Map[opcode] then
        add_to_list(NextOnes, next_instruction_index)
        add_to_list(NextOnes, next_instruction_index + 1)
      elseif ForwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif ForwardJumpersAndSkippers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index)
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif BackwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index)
        add_to_list(NextOnes, next_instruction_index - jump_offset)
      else
        add_to_list(NextOnes, next_instruction_index)
      end

      return NextOnes
    end
end

-- Export:
return get_next_ones

--[[
  2026-07-15
]]
