-- Return table with possible next instructions indices

--[[
  Author: Martin Eden
  Last mod.: 2026-07-29
]]

-- Core of this ship

--[[
  Checked for Lua versions from 5.3 to 5.5.

  ..

  After good bath thinking we decided to diverge this module into
  two instances. Because VM in 5.4 changed logic of existing
  instruction (and added moar instructionz).

  Each instance will start with knowledge about flow-related
  instructions for their VM.

  Each instance must return result that complies with common
  interface (aka function "get_next_one(bla, bla)").
]]

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
    local Skippers
    local Jumpers
    local ForwardJumpers
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

      Jumpers =
        {
          FlowOpcodes.jump,
        }

      ForwardJumpers =
        {
          FlowOpcodes.check_generic_loop,
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
    Skippers_Map = map_values(Skippers)
    Jumpers_Map = map_values(Jumpers)
    ForwardJumpers_Map = map_values(ForwardJumpers)
    SkippersAndForwardJumpers_Map = map_values(SkippersAndForwardJumpers)
    SkippersAndBackwardJumpers_Map = map_values(SkippersAndBackwardJumpers)
  end

  local add_to_list = request('!.concepts.list.add_item')

  local jump_offset_is_signed
  local unused_op_in_jump
  do
    local is_ancient_lua =
      (_G._VERSION ~= 'Lua 5.4') and
      (_G._VERSION ~= 'Lua 5.5')
    jump_offset_is_signed = is_ancient_lua
    unused_op_in_jump = is_ancient_lua
  end

  get_next_ones =
    function(instruction_index, Instruction)
      local NextOnes = { }

      local opcode = Instruction[1]
      local next_instruction_index = instruction_index + 1

      if Terminators_Map[opcode] then
        ;
      elseif Skippers_Map[opcode] then
        add_to_list(NextOnes, next_instruction_index)
        add_to_list(NextOnes, next_instruction_index + 1)
      elseif Jumpers_Map[opcode] then
        local jump_offset
        if unused_op_in_jump then
          jump_offset = Instruction[3]
        else
          jump_offset = Instruction[2]
        end
        jump_offset = tonumber(jump_offset)
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif ForwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif SkippersAndForwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        add_to_list(NextOnes, next_instruction_index)
        add_to_list(NextOnes, next_instruction_index + jump_offset)
      elseif SkippersAndBackwardJumpers_Map[opcode] then
        local jump_offset = tonumber(Instruction[3])
        if jump_offset_is_signed then
          jump_offset = -jump_offset
        end
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
  2026-07-29
]]
