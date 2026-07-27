-- Return next possible instruction offsets for given instruction

--[[
  Author: Martin Eden
  Last mod.: 2026-09-04
]]

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

-- Export:
return
  function(Instruction)
    local NextOffs = { }

    local opcode = Instruction[1]

    if Terminators_Map[opcode] then
      ;
    elseif (opcode == opcode_jmp) then
      add_to_list(NextOffs, tonumber(Instruction[3]) + 1)
    elseif BasicForks_Map[opcode] then
      add_to_list(NextOffs, 1)
      add_to_list(NextOffs, 2)
    elseif Loopbacks_Map[opcode] then
      add_to_list(NextOffs, tonumber(Instruction[3]) + 1)
      add_to_list(NextOffs, 1)
    elseif (opcode == opcode_forprep) then
      add_to_list(NextOffs, tonumber(Instruction[3]) + 1)
    else
      add_to_list(NextOffs, 1)
    end

    return NextOffs
  end

--[[
  2026 #
  2026-09-04
]]
