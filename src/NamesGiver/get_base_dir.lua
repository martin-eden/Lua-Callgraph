-- Return normalized directory name

--[[
  Author: Martin Eden
  Last mod.: 2026-07-23
]]

-- Imports:
local add_dir_postfix = request('!.concepts.path_name.add_dir_postfix')
local normalize_pathname = request('!.concepts.path_name.normalize')

local get_base_dir =
  function(output_dir_name)
    return normalize_pathname(add_dir_postfix(output_dir_name))
  end

-- Export:
return get_base_dir

--[[
  2026-07-23
]]
