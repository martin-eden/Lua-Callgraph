-- Return file name from pathname

--[[
  Author: Martin Eden
  Last mod.: 2026-07-23
]]

-- Imports:
local get_path_from_str = request('!.concepts.path_name.pathname_from_str')
local get_name_from_path = request('!.concepts.path_name.get_name')

local get_file_name =
  function(source_code_path_name)
    return get_name_from_path(get_path_from_str(source_code_path_name))
  end

-- Export:
return get_file_name

--[[
  2026-07-23
]]
