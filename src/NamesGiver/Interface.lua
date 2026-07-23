-- Generate needed names from source file output dir names

--[[
  Author: Martin Eden
  Last mod.: 2026-07-23
]]

-- Imports:
local create_instance = request('!.table.create_instance')
local get_base_dir = request('get_base_dir')
local get_source_file_name = request('get_source_file_name')

local str_dot = 'dot'
local str_tgf = 'tgf'

--[[
  Core storage format:

    1 [s] source_code_path_name
    2 [s] output_dir_name
]]

local Methods
Methods =
  {
    create =
      function(source_code_path_name, output_dir_name)
        local Core = { source_code_path_name, output_dir_name }

        return create_instance(Core, Methods)
      end,

    get_tgf_dir =
      function(Me)
        return Me:get_base_dir() .. Me.str_tgf
      end,

    get_dot_dir =
      function(Me)
        return Me:get_base_dir() .. Me.str_dot
      end,

    get_base_dir =
      function(Me)
        return get_base_dir(Me[2])
      end,

    get_source_file_name =
      function(Me)
        return get_source_file_name(Me[1])
      end,

    -- Internals:
    str_tgf = str_tgf,
    str_dot = str_dot,
  }

-- Export:
return Methods

--[[
  2026-07-23
]]
