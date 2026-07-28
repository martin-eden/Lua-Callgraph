-- Return table with possible next instructions indices

--[[
  Author: Martin Eden
  Last mod.: 2026-07-28
]]

-- Core of this ship

-- Implemented for Lua 5.5 opcodes and their semantics

local get_next_ones
do
  local Terminators_Map
  local Jumpers_Map
  local ForwardJumpers_Map
  local Skippers_Map
  local SkippersAndForwardJumpers_Map
  local SkippersAndBackwardJumpers_Map
  do
    local Terminators
    local Jumpers
    local ForwardJumpers
    local Skippers
    local SkippersAndForwardJumpers
    local SkippersAndBackwardJumpers
    do
      local FlowOpcodes = request('FlowOpcodes')

      Terminators =
        {
          FlowOpcodes.return_nothing,
          FlowOpcodes.return_item,
          FlowOpcodes.return_sequence,
        }

      Jumpers =
        {
          FlowOpcodes.jump,
        }

      ForwardJumpers =
        {
          FlowOpcodes.check_generic_loop,
        }

      Skippers =
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

      SkippersAndForwardJumpers =
        {
          FlowOpcodes.check_numeric_loop,
        }

      SkippersAndBackwardJumpers =
        {
          FlowOpcodes.numeric_loop_back,
          FlowOpcodes.generic_loop_back,
        }
    end

    local map_values = request('!.table.map_values')

    Terminators_Map = map_values(Terminators)
    Jumpers_Map = map_values(Jumpers)
    ForwardJumpers_Map = map_values(ForwardJumpers)
    Skippers_Map = map_values(Skippers)
    SkippersAndForwardJumpers_Map = map_values(SkippersAndForwardJumpers)
    SkippersAndBackwardJumpers_Map = map_values(SkippersAndBackwardJumpers)
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
      elseif ForwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif Skippers_Map[opcode] then
        add_to_list(NextOnes, next_instruction_index)
        add_to_list(NextOnes, next_instruction_index + 1)
      elseif SkippersAndForwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index)
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif SkippersAndBackwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index - jump_offset)
        add_to_list(NextOnes, next_instruction_index)
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
