-- Create callgraph from Lua function bytecode instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-07-17
]]

-- package.path = package.path .. ';../../?.lua'
require('workshop.base')

local process_chunk
do
  local get_next_ones = request('callgraph.get_next_ones')
  local list_to_str = request('!.concepts.list.to_string')
  local add_to_list = request('!.concepts.list.add_item')

  process_chunk =
    function(Chunk)
      local Callgraph = { }

      for instruction_index, Instruction in ipairs(Chunk) do
        local CallgraphRec =
          {
            label = list_to_str(Instruction, ' '),
            NextOnes = get_next_ones(instruction_index, Instruction),
          }

        add_to_list(Callgraph, CallgraphRec)
      end

      return Callgraph
    end
end

local export_to_tgf
local export_to_dot
do
  local OutputFileStream = request('!.concepts.StreamIo.Output.File')
  do
    local callgraph_to_tgf = request('callgraph.callgraph_to_tgf')
    export_to_tgf =
      function(InstructionsGraph, file_name)
        local OutputStream = new(OutputFileStream)
        OutputStream:Open(file_name)
        callgraph_to_tgf(InstructionsGraph, OutputStream)
        OutputStream:Close()
      end
  end
  do
    local callgraph_to_dot = request('callgraph.callgraph_to_dot')
    export_to_dot =
      function(InstructionsGraph, graph_name, file_name)
        local OutputStream = new(OutputFileStream)
        OutputStream:Open(file_name)
        callgraph_to_dot(InstructionsGraph, graph_name, OutputStream)
        OutputStream:Close()
      end
  end
end

local Config =
  {
    source_code_file_name = arg[1],
  }

local print_help
do
  local usage_text =
[[

Creates call graphs for Lua code.

Usage: <lua_file_name>

Writes results to ./output/ .

-- Martin, 2026-07
]]
  print_help =
    function()
      io.stdout:write(usage_text)
    end
end

local file_to_str = request('!.convert.file_to_str')
local get_bytecode =
  request('!.concepts.lua_bytecode_decompiler.bytecode_from_source')
local get_listing =
  request('!.concepts.lua_bytecode_decompiler.listing_from_bytecode')

local tgf_name_format = 'output/callgraph_%d.tgf'
local dot_name_format = 'output/callgraph_%d.dot'

local str_format = string.format

-- Main:
do
  local source_code_file_name = Config.source_code_file_name
  if not source_code_file_name then
    print_help()
    return
  end

  local source_code_str = file_to_str(source_code_file_name)
  local bytecode = get_bytecode(source_code_str)
  local Chunks = get_listing(bytecode)

  for function_index, Chunk in ipairs(Chunks) do
    local InstructionsGraph = process_chunk(Chunk)
    do
      local file_name = str_format(tgf_name_format, function_index)
      export_to_tgf(InstructionsGraph, file_name)
    end
    do
      local file_name = str_format(dot_name_format, function_index)
      local graph_name = 'Callgraph_' .. function_index
      export_to_dot(InstructionsGraph, graph_name, file_name)
    end
  end
end

--[[
  2026-07-15
  2026-07-17
]]
