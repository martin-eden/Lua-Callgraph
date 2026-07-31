-- Generate needed names from source file and output dir names

--[[
  Author: Martin Eden
  Last mod.: 2026-07-31
]]

local create_instance = request('!.table.create_instance')

--[[
  Core storage format:

    1 [s] output_dir_name
    2 [s] source_code_path_name
    3 [i] num_items
]]
local DefaultCore = { [1] = '', [2] = '', [3] = 0 }

local set_output_dir
do
  local get_base_dir = request('get_base_dir')
  set_output_dir =
    function(Me, output_dir_name)
      Me[1] = get_base_dir(output_dir_name)
    end
end

local get_base_dir = function(Me) return Me[1] end

local set_source_name
do
  local get_file_name = request('get_file_name')
  set_source_name =
    function(Me, source_file_name)
      Me[2] = get_file_name(source_file_name)
    end
end

local get_source_name = function(Me) return Me[2] end

local set_num_items =
  function(Me, num_items)
    Me[3] = num_items
  end

local get_num_items = function(Me) return Me[3] end

local get_tgf_dir
local get_dot_dir
local get_tgf_pathname
local get_dot_pathname
local get_dot_graphname
do
  local str_tgf = 'tgf'
  local str_dot = 'dot'

  get_tgf_dir =
    function(Me)
      return get_base_dir(Me) .. str_tgf
    end

  get_dot_dir =
    function(Me)
      return get_base_dir(Me) .. str_dot
    end

  local slash
  local dot
  do
    local Ascii = request('^.concepts.Ascii')
    slash = Ascii.slash
    dot = Ascii.dot
  end

  do
    local get_padded_number_format = request('get_padded_number_format')
    local str_format = string.format

    do
      local get_tgf_pathname_format =
        function(Me)
          return
            get_tgf_dir(Me) ..
            slash ..
            get_source_name(Me) ..
            dot ..
            get_padded_number_format(get_num_items(Me)) ..
            dot ..
            str_tgf
        end
      get_tgf_pathname =
        function(Me, index)
          return str_format(get_tgf_pathname_format(Me), index)
        end
    end

    do
      local get_dot_pathname_format =
        function(Me)
          return
            get_dot_dir(Me) ..
            slash ..
            get_source_name(Me) ..
            dot ..
            get_padded_number_format(get_num_items(Me)) ..
            dot ..
            str_dot
        end
      get_dot_pathname =
        function(Me, index)
          return str_format(get_dot_pathname_format(Me), index)
        end
    end

    do
      local get_dot_graphname_format =
        function(Me)
          return
            get_source_name(Me) ..
            dot ..
            get_padded_number_format(get_num_items(Me))
        end
      get_dot_graphname =
        function(Me, index)
          return str_format(get_dot_graphname_format(Me), index)
        end
    end
  end
end

local Methods
Methods =
  {
    create =
      function()
        return create_instance(DefaultCore, Methods)
      end,

    SetBaseDir = set_output_dir,
    SetSourceName = set_source_name,
    SetNumItems = set_num_items,

    GetTgfDir = get_tgf_dir,
    GetDotDir = get_dot_dir,

    GetTgfPathname = get_tgf_pathname,
    GetDotPathname = get_dot_pathname,
    GetDotGraphname = get_dot_graphname,
  }

-- Export:
return Methods

--[[
  2026-07-23
  2026-07-31
]]
