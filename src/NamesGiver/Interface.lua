-- Generate needed names from source file and output dir names

--[[
  Author: Martin Eden
  Last mod.: 2026-07-31
]]

local create_instance = request('!.table.create_instance')

--[[
  Core storage format:

    1 [s] output directory
    2 [s] source code pathname
    3 [t] PaddedIndex which depends from number of items
]]

local set_output_dir
do
  local get_base_dir = request('get_base_dir')
  set_output_dir =
    function(Me, output_dir_name)
      Me[1] = get_base_dir(output_dir_name)
    end
end

local get_output_dir = function(Me) return Me[1] end

local set_source_name
do
  local get_file_name = request('get_file_name')
  set_source_name =
    function(Me, source_file_name)
      Me[2] = get_file_name(source_file_name)
    end
end

local get_source_name = function(Me) return Me[2] end

local set_num_items
do
  local PaddedIndex = request('!.concepts.PaddedIndex')
  set_num_items =
    function(Me, num_items)
      Me[3] = PaddedIndex.create(num_items)
    end
end

local get_padded_index =
  function(Me, index)
    return Me[3]:ToString(index)
  end

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
      return get_output_dir(Me) .. str_tgf
    end

  get_dot_dir =
    function(Me)
      return get_output_dir(Me) .. str_dot
    end

  local slash
  local dot
  do
    local Ascii = request('^.concepts.Ascii')
    slash = Ascii.slash
    dot = Ascii.dot
  end

  get_tgf_pathname =
    function(Me, index)
      return
        get_tgf_dir(Me) ..
        slash ..
        get_source_name(Me) ..
        dot ..
        get_padded_index(Me, index) ..
        dot ..
        str_tgf
    end

  get_dot_pathname =
    function(Me, index)
      return
        get_dot_dir(Me) ..
        slash ..
        get_source_name(Me) ..
        dot ..
        get_padded_index(Me, index) ..
        dot ..
        str_dot
    end

  get_dot_graphname =
    function(Me, index)
      return
        get_source_name(Me) ..
        dot ..
        get_padded_index(Me, index)
    end
end

local Methods
Methods =
  {
    create =
      function()
        -- Allocate data slots. Data setup is done via methods.
        local Core = { [1] = false, [2] = false, [3] = false }

        return create_instance(Core, Methods)
      end,

    SetOutputDir = set_output_dir,
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
