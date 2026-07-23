-- Create callgraph from Lua function bytecode instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-07-23
]]

package.path = package.path .. ';../../../?.lua'
require('workshop.base')

--[[
  Get parsed closure listings from source code file
]]
local get_chunks
do
  local file_to_str = request('!.convert.file_to_str')
  local get_bytecode =
    request('!.concepts.lua_bytecode_decompiler.bytecode_from_source')
  local get_listing =
    request('!.concepts.lua_bytecode_decompiler.listing_from_bytecode')
  get_chunks =
    function(source_code_path_name)
      return get_listing(get_bytecode(file_to_str(source_code_path_name)))
    end
end

--[[
  Create callgraph for given parsed closure listing

  Sample input (Itness format):

    (
      ( TEST 9 0 )
      ( JMP 3 )
      ( GETUPVAL 10 6 )
    )

  Sample output (Lua format):

    {
      [1] = { label = 'TEST 9 0', NextOnes = { 2, 3 } },
      [2] = { label = 'JMP 3', NextOnes = { 6 } },
      [3] = { label = 'GETUPVAL 10 6', NextOnes = { 4 } },
    }
]]
local get_callgraph
do
  local space = ' '
  local list_to_str = request('!.concepts.list.to_string')
  local get_next_ones = request('callgraph.get_next_ones')
  local add_to_list = request('!.concepts.list.add_item')
  get_callgraph =
    function(Chunk)
      local Callgraph = { }

      for instruction_index, Instruction in ipairs(Chunk) do
        local CallgraphRec =
          {
            label = list_to_str(Instruction, space),
            NextOnes = get_next_ones(instruction_index, Instruction),
          }
        add_to_list(Callgraph, CallgraphRec)
      end

      return Callgraph
    end
end

--[[
  Export callgraph to .tgf file
]]
local export_to_tgf
do
  local OutputFileStream = request('!.concepts.StreamIo.Output.File')
  local callgraph_to_tgf = request('callgraph.callgraph_to_tgf')
  export_to_tgf =
    function(Callgraph, file_name)
      local OutputStream = new(OutputFileStream)
      OutputStream:Open(file_name)
      callgraph_to_tgf(Callgraph, OutputStream)
      OutputStream:Close()
    end
end

--[[
  Export callgraph to .dot file
]]
local export_to_dot
do
  local OutputFileStream = request('!.concepts.StreamIo.Output.File')
  local callgraph_to_dot = request('callgraph.callgraph_to_dot')
  export_to_dot =
    function(Callgraph, graph_name, file_name)
      local OutputStream = new(OutputFileStream)
      OutputStream:Open(file_name)
      callgraph_to_dot(Callgraph, graph_name, OutputStream)
      OutputStream:Close()
    end
end

local NamesGiver = request('NamesGiver.Interface')

local usage_text =
[[

Creates call graphs for Lua code.

Usage: <lua_file_name> <output_dir>

-- Martin, 2026-07
]]

local Config =
  {
    source_code_path_name = arg[1],
    output_dir_name = arg[2],
  }

-- Main:
do
  local source_code_path_name = Config.source_code_path_name
  local output_dir_name = Config.output_dir_name

  if not (source_code_path_name and output_dir_name) then
    io.stdout:write(usage_text)
    return
  end

  NamesGiver = NamesGiver.create(source_code_path_name, output_dir_name)

  local str_tgf = 'tgf'
  local str_dot = 'dot'

  local base_dir = NamesGiver:get_base_dir()

  do
    local remove_dir = request('!.file_system.directory.remove')
    local create_dir = request('!.file_system.directory.create')

    local tgf_dir = NamesGiver:get_tgf_dir()
    remove_dir(tgf_dir)
    create_dir(tgf_dir)

    local dot_dir = NamesGiver:get_dot_dir()
    remove_dir(dot_dir)
    create_dir(dot_dir)
  end

  local get_padded_number_format
  do
    local get_num_digits = request('!.number.get_num_dec_digits')
    local int_to_str = tostring
    get_padded_number_format =
      function(num_items)
        local num_digits = get_num_digits(num_items)
        return '%0' .. int_to_str(num_digits) .. 'd'
      end
  end

  local get_tgf_path_name_format
  local get_dot_path_name_format
  local get_dot_graph_name_format
  do
    local slash = '/'
    local underscore = '_'
    local dot = '.'

    get_tgf_path_name_format =
      function(source_file_name, output_dir_name, num_items)
        local tgf_dir = NamesGiver:get_tgf_dir()
        local num_format = get_padded_number_format(num_items)
        return
          tgf_dir ..
          slash ..
          source_file_name ..
          dot ..
          num_format ..
          dot ..
          str_tgf
      end

    get_dot_path_name_format =
      function(source_file_name, output_dir_name, num_items)
        local dot_dir = NamesGiver:get_dot_dir()
        local num_format = get_padded_number_format(num_items)
        return
          dot_dir ..
          slash ..
          source_file_name ..
          dot ..
          num_format ..
          dot ..
          str_dot
      end

    get_dot_graph_name_format =
      function(source_file_name, num_items)
        local num_format = get_padded_number_format(num_items)
        return
          source_file_name ..
          underscore ..
          num_format
      end
  end

  local Chunks = get_chunks(source_code_path_name)
  local num_chunks = #Chunks

  local source_file_name = NamesGiver:get_source_file_name()

  local tgf_file_name_format =
    get_tgf_path_name_format(source_file_name, output_dir_name, num_chunks)
  local dot_file_name_format =
    get_dot_path_name_format(source_file_name, output_dir_name, num_chunks)
  local dot_graph_name_format =
    get_dot_graph_name_format(source_file_name, num_chunks)

  local str_format = string.format

  for chunk_index, Chunk in ipairs(Chunks) do
    local Callgraph = get_callgraph(Chunk)
    do
      local file_name = str_format(tgf_file_name_format, chunk_index)
      export_to_tgf(Callgraph, file_name)
    end
    do
      local graph_name = str_format(dot_graph_name_format, chunk_index)
      local file_name = str_format(dot_file_name_format, chunk_index)
      export_to_dot(Callgraph, graph_name, file_name)
    end
  end
end

--[[
  2026-07-15
  2026-07-17
  2026-07-23
]]
