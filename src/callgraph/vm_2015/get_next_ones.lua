-- Return next possible instruction indices for given instruction

--[[
  Author: Martin Eden
  Last mod.: 2026-07-30
]]

local get_next_ones
do
  local Terminators_Map
  local opcode_jmp
  local BasicForks_Map
  local Loopbacks_Map
  local opcode_forprep
  do
    local FlowOpcodes = request('FlowOpcodes')
    local map_values = request('!.table.map_values')

    Terminators_Map = map_values(FlowOpcodes[1])
    opcode_jmp = FlowOpcodes[2]
    BasicForks_Map = map_values(FlowOpcodes[3])
    Loopbacks_Map = map_values(FlowOpcodes[4])
    opcode_forprep = FlowOpcodes[5]
  end

  local add_to_list = request('!.concepts.list.add_item')

  get_next_ones =
    function(instruction_index, Instruction)
      local NextOnes = { }

      local opcode = Instruction[1]
      local next_instruction = instruction_index + 1

      if Terminators_Map[opcode] then
        ;
      elseif (opcode == opcode_jmp) then
        add_to_list(NextOnes, next_instruction + tonumber(Instruction[3]))
      elseif BasicForks_Map[opcode] then
        add_to_list(NextOnes, next_instruction)
        add_to_list(NextOnes, next_instruction + 1)
      elseif Loopbacks_Map[opcode] then
        add_to_list(NextOnes, next_instruction + tonumber(Instruction[3]))
        add_to_list(NextOnes, next_instruction)
      elseif (opcode == opcode_forprep) then
        add_to_list(NextOnes, next_instruction + tonumber(Instruction[3]))
      else
        add_to_list(NextOnes, next_instruction)
      end

      return NextOnes
    end
end

-- Export:
return get_next_ones

--[[
  2026-07-30
]]
