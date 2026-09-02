-- Create callgraphs from Lua function bytecode instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-09-01
]]

require('workshop.base')

local AsciiChars = request('!.concepts.Ascii.Chars')

--[[
  Get parsed closure listings from source code file
]]
local get_chunks
do
  local get_bytecode_listing = request('!.programs.get_bytecode_listing')
  local StringStream = request('!.concepts.StreamIo.Output.String')
  local itness_from_str = request('!.convert.itness_from_str')

  get_chunks =
    function(source_code_path_name)
      local StringStream = new(StringStream)

      get_bytecode_listing({ source_code_path_name }, StringStream)

      return itness_from_str(StringStream:GetString())
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
  local space = AsciiChars.space
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

-- Export callgraph to .tgf file
local export_to_tgf
-- Export callgraph to .dot file
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

local usage_text =
[[
Creates VM instruction call graphs for Lua code

Usage: <lua_file_name> <output_dir>

-- Martin, 2026-07
]]

local Config =
  {
    source_code_path_name = arg[1],
    output_dir_name = arg[2],
  }

local console_write =
  function(str)
    io.stdout:write(str)
  end

local console_print
do
  local newline = AsciiChars.newline
  console_print =
    function(str)
      console_write(str)
      console_write(newline)
    end
end

-- Main
do
  local NamesGiver
  NamesGiver = request('NamesGiver')
  NamesGiver = NamesGiver.create()

  local Chunks

  do
    local source_code_path_name = Config.source_code_path_name
    local output_dir_name = Config.output_dir_name

    if not (source_code_path_name and output_dir_name) then
      console_write(usage_text)
      return
    end

    console_print('( Generating callgraphs')

    NamesGiver:SetSourceName(source_code_path_name)
    NamesGiver:SetOutputDir(output_dir_name)

    do
      local remove_dir = request('!.file_system.directory.remove')
      local create_dir = request('!.file_system.directory.create')
      do
        local tgf_dir = NamesGiver:GetTgfDir()
        remove_dir(tgf_dir)
        create_dir(tgf_dir)
      end
      do
        local dot_dir = NamesGiver:GetDotDir()
        remove_dir(dot_dir)
        create_dir(dot_dir)
      end
    end

    Chunks = get_chunks(source_code_path_name)
  end

  NamesGiver:SetNumItems(#Chunks)

  for chunk_index, Chunk in ipairs(Chunks) do
    local Callgraph = get_callgraph(Chunk)
    do
      local file_name = NamesGiver:GetTgfPathname(chunk_index)
      export_to_tgf(Callgraph, file_name)
    end
    do
      local graph_name = NamesGiver:GetDotGraphname(chunk_index)
      local file_name = NamesGiver:GetDotPathname(chunk_index)
      export_to_dot(Callgraph, graph_name, file_name)
    end
  end

  console_print(')')
end

--[[
  2026-07-15
  2026-07-17
  2026-07-23
  2026-07-31
]]
