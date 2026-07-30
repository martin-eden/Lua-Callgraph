-- Load core function to determine next instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-07-30
]]

local get_next_ones

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
    get_next_ones = request('vm_2015.get_next_ones')
  elseif use_vm_2020 then
    get_next_ones = request('vm_2020.get_next_ones')
  end
end

-- Export:
return get_next_ones

--[[
  2026-07-15
  2026-07-29
  2026-07-30
]]
