-- Create callgraphs from Lua function bytecode instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-09-02
]]

require('workshop.base')

local space
local newline
do
  local AsciiChars = request('!.concepts.Ascii.Chars')
  space = AsciiChars.space
  newline = AsciiChars.newline
end

--[[
  Get parsed closure listings from source code file
]]
local get_chunks
do
  local get_bytecode_listing = request('!.programs.get_bytecode_listing')
  local StringStream = request('!.concepts.StreamIo.Output.String')
  local itness_from_str = request('!.convert.itness_from_str')

  get_chunks =
    function(sourcecode_pathname)
      local StringStream = new(StringStream)

      get_bytecode_listing({ sourcecode_pathname }, StringStream)

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

local export_to_tgf
local export_to_dot
do
  local OutputFileStream = request('!.concepts.StreamIo.Output.File')
  do
    local callgraph_to_tgf = request('callgraph.callgraph_to_tgf')
    -- Export callgraph to .tgf file
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
    -- Export callgraph to .dot file
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
    sourcecode_pathname = arg[1],
    output_dir_name = arg[2],
  }

local console_write =
  function(str)
    io.stdout:write(str)
  end

local console_print =
  function(str)
    console_write(str)
    console_write(newline)
  end

local NamesGiver = request('NamesGiver').create()

-- Main
do
  local sourcecode_pathname = Config.sourcecode_pathname
  local output_dir_name = Config.output_dir_name

  if not (sourcecode_pathname and output_dir_name) then
    console_write(usage_text)
    return
  end

  console_print('( Generating callgraphs')

  NamesGiver:SetSourceName(sourcecode_pathname)
  NamesGiver:SetOutputDir(output_dir_name)

  do
    local recreate_dir = request('!.file_system.directory.recreate')
    recreate_dir(NamesGiver:GetTgfDir())
    recreate_dir(NamesGiver:GetDotDir())
  end

  do
    local Chunks = get_chunks(sourcecode_pathname)

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
  end

  console_print(')')
end

--[[
  2026 # # # #
  2026-09-02
]]
