-- Create callgraph from Lua function bytecode instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-07-17
]]

package.path = package.path .. ';../../?.lua'
require('workshop.base')

local Config =
  {
    source_code_file_name = arg[1],
    output_dir_name = arg[2],
  }

-- Main:
do
  local Chunks
  do
    local bytecode
    do
      local source_code_str
      do
        local source_code_file_name = Config.source_code_file_name
        local output_dir_name = Config.output_dir_name
        do
          if not (source_code_file_name and output_dir_name) then
            local usage_text =
[[

Creates call graphs for Lua code.

Usage: <lua_file_name> <output_dir>

-- Martin, 2026-07
]]

            io.stdout:write(usage_text)
            return
          end
        end
        local file_to_str = request('!.convert.file_to_str')
        source_code_str = file_to_str(source_code_file_name)
      end
      local get_bytecode =
        request('!.concepts.lua_bytecode_decompiler.bytecode_from_source')
      bytecode = get_bytecode(source_code_str)
    end
    local get_listing =
      request('!.concepts.lua_bytecode_decompiler.listing_from_bytecode')
    Chunks = get_listing(bytecode)
  end

  local get_callgraph
  do
    local get_next_ones = request('callgraph.get_next_ones')
    local list_to_str = request('!.concepts.list.to_string')
    local add_to_list = request('!.concepts.list.add_item')

    get_callgraph =
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
        function(Callgraph, file_name)
          local OutputStream = new(OutputFileStream)
          OutputStream:Open(file_name)
          callgraph_to_tgf(Callgraph, OutputStream)
          OutputStream:Close()
        end
    end
    do
      local callgraph_to_dot = request('callgraph.callgraph_to_dot')
      export_to_dot =
        function(Callgraph, graph_name, file_name)
          local OutputStream = new(OutputFileStream)
          OutputStream:Open(file_name)
          callgraph_to_dot(Callgraph, graph_name, OutputStream)
          OutputStream:Close()
        end
    end
  end

  local tgf_name_format = 'output/callgraph_%d.tgf'
  local dot_name_format = 'output/callgraph_%d.dot'

  local str_format = string.format

  for chunk_index, Chunk in ipairs(Chunks) do
    local Callgraph = get_callgraph(Chunk)
    do
      local file_name = str_format(tgf_name_format, chunk_index)
      export_to_tgf(Callgraph, file_name)
    end
    do
      local file_name = str_format(dot_name_format, chunk_index)
      local graph_name = 'Callgraph_' .. chunk_index
      export_to_dot(Callgraph, graph_name, file_name)
    end
  end
end

--[[
  2026-07-15
  2026-07-17
]]
