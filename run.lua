-- Create callgraph from Lua function bytecode instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-07-15
]]

package.path = package.path .. ';../../?.lua'
require('workshop.base')

local process_function
do
  local get_next_ones = request('callgraph.get_next_ones')
  local list_to_str = request('!.concepts.list.to_string')
  local add_to_list = request('!.concepts.list.add_item')

  process_function =
    function(Function)
      local Callgraph = { }

      for instruction_index, Instruction in ipairs(Function) do
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

  local callgraph_to_tgf = request('callgraph.callgraph_to_tgf')

  export_to_tgf =
    function(InstructionsGraph, file_name)
      local OutputStream = new(OutputFileStream)

      OutputStream:Open(file_name)

      callgraph_to_tgf(InstructionsGraph, OutputStream)

      OutputStream:Close()
    end

  local callgraph_to_dot = request('callgraph.callgraph_to_dot')

  export_to_dot =
    function(InstructionsGraph, file_name)
      local OutputStream = new(OutputFileStream)

      OutputStream:Open(file_name)

      callgraph_to_dot(InstructionsGraph, OutputStream)

      OutputStream:Close()
    end
end

local Config =
  {
    source_code_file_name = arg[1],
  }

local print_help =
  function()
    print(
      '\n' ..
      'Creates call graphs for Lua code.' .. '\n' ..
      '\n' ..
      'Usage: <lua_file_name>' .. '\n' ..
      '\n' ..
      'Writes results to ./output/ .' .. '\n' ..
      '\n' ..
      '-- Martin, 2026-07' .. '\n'
    )
  end

-- Main:
do
  local t2s = request('!.convert.value_to_str')

  local source_code_str
  do
    local file_to_str = request('!.convert.file_to_str')

    local source_code_file_name = Config.source_code_file_name

    if not source_code_file_name then
      print_help()
      return
    end

    source_code_str = file_to_str(source_code_file_name)
  end

  local get_bytecode =
    request('!.concepts.lua_bytecode_decompiler.bytecode_from_source')
  local get_listing =
    request('!.concepts.lua_bytecode_decompiler.listing_from_bytecode')

  local bytecode = get_bytecode(source_code_str)
  local Functions = get_listing(bytecode)

  -- print(t2s(Functions))

  local tgf_name_format = 'output/callgraph_%d.tgf'
  local dot_name_format = 'output/callgraph_%d.dot'

  local str_format = string.format

  for function_index, Function in ipairs(Functions) do
    local InstructionsGraph = process_function(Functions[function_index])

    -- print(t2s(InstructionsGraph))

    local tgf_file_name = str_format(tgf_name_format, function_index)
    export_to_tgf(InstructionsGraph, tgf_file_name)

    local dot_file_name = str_format(dot_name_format, function_index)
    export_to_dot(InstructionsGraph, dot_file_name)
  end
end

--[[
  2026-07-15
]]
