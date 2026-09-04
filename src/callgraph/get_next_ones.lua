-- Core function to determine next instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-09-04
]]

local get_next_offs
do
  local use_vm_2015
  local use_vm_2020
  do
    local is_lua_53 = (_VERSION == 'Lua 5.3')
    local is_lua_54 = (_VERSION == 'Lua 5.4')
    local is_lua_55 = (_VERSION == 'Lua 5.5')

    use_vm_2015 = is_lua_53
    use_vm_2020 = is_lua_54 or is_lua_55
  end

  if use_vm_2015 then
    get_next_offs = request('vm_2015.get_next_offs')
  elseif use_vm_2020 then
    get_next_offs = request('vm_2020.get_next_offs')
  end
end

local add_to_list = request('!.concepts.list.add_item')

-- Export:
return
  function(instruction_index, Instruction)
    local NextOffs = get_next_offs(Instruction)

    local NextOnes = { }
    for _, offs in ipairs(NextOffs) do
      add_to_list(NextOnes, instruction_index + offs)
    end

    return NextOnes
  end

--[[
  2026 # # #
  2026-09-04
]]
