-- Create callgraphs for Lua VM instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-09-22
]]

require('workshop.base')

local space
local newline
do
  local AsciiChars = request('!.concepts.Ascii.Chars')
  space = AsciiChars.space
  newline = AsciiChars.newline
end

local export_listing
do
  local get_bytecode_listing = request('!.programs.get_bytecode_listing')
  local FileStream = request('!.concepts.StreamIo.Output.File')
  export_listing =
    function(sourcecode_pathname, listing_pathname)
      local ListingStream = new(FileStream)
      ListingStream:Open(listing_pathname)
      get_bytecode_listing({ sourcecode_pathname }, ListingStream)
      ListingStream:Close()
    end
end

local load_listing
do
  local parse_itness = request('!.concepts.codec_itness.parse')
  local FileStream = request('!.concepts.StreamIo.Input.File')
  load_listing =
    function(listing_pathname)
      local Result
      local ListingStream = new(FileStream)
      ListingStream:Open(listing_pathname)
      Result = parse_itness(ListingStream)
      ListingStream:Close()
      return Result
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
local export_to_mmd
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
      function(Callgraph, file_name)
        local OutputStream = new(OutputFileStream)
        OutputStream:Open(file_name)
        callgraph_to_dot(Callgraph, OutputStream)
        OutputStream:Close()
      end
  end
  do
    local callgraph_to_mmd = request('callgraph.callgraph_to_mmd')
    export_to_mmd =
      function(Callgraph, file_name)
        local OutputStream = new(OutputFileStream)
        OutputStream:Open(file_name)
        callgraph_to_mmd(Callgraph, OutputStream)
        OutputStream:Close()
      end
  end
end

local dot_to_svg
do
  local get_cmd_dot_to_svg =
    request('!.mechs.cmdline.get_cmd_dot_to_svg')
  dot_to_svg =
    function(dot_pathname, svg_pathname)
      local Command = get_cmd_dot_to_svg(dot_pathname, svg_pathname)
      local is_ok, Result = Command:Execute()
      if not is_ok then
        error(Result.error)
      end
    end
end

local words_to_str = request('!.concepts.words.to_string')

local ValidWishes = { 'tgf', 'dot', 'svg', 'mmd' }

local usage_text =
[[
Creates VM instruction call graphs for Lua code

Usage: <lua_file_name> <output_dir> [<wishes>]

Careful, we will recreate <output_dir>!

<wishes> is a string with space-separated words of what to export
  You have to quote it for shell.
  Possible wishes: ]] ..
  words_to_str(ValidWishes) ..
[[

  If <wishes> is empty we will process all possible wishes.

-- Martin, 2026-09
]]

local Config =
  {
    sourcecode_pathname = arg[1],
    output_dir_name = arg[2],
    wishes_str = arg[3],
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
local get_wishes = request('get_wishes')

-- Main
do
  local sourcecode_pathname = Config.sourcecode_pathname
  local output_dir_name = Config.output_dir_name
  local wishes_str = Config.wishes_str or ''

  if not (sourcecode_pathname and output_dir_name) then
    console_write(usage_text)
    return
  end

  console_print('( Generating callgraphs')

  NamesGiver:SetOutputDir(output_dir_name)

  local Wishes =
    get_wishes(
      wishes_str,
      ValidWishes,
      {
        empty_means_all = true,
        explode_on_unknown = true,
      }
    )

  local action_export_tgf
  local action_export_dot
  local action_export_svg
  local action_export_mmd
  do
    action_export_tgf = Wishes.tgf
    action_export_dot = Wishes.dot or Wishes.svg
    action_export_svg = Wishes.svg
    action_export_mmd = Wishes.mmd
  end

  do
    local recreate_dir = request('!.file_system.directory.recreate')
    recreate_dir(NamesGiver:GetOutputDir())
    if action_export_tgf then
      recreate_dir(NamesGiver:GetTgfDir())
    end
    if action_export_dot then
      recreate_dir(NamesGiver:GetDotDir())
    end
    if action_export_svg then
      recreate_dir(NamesGiver:GetSvgDir())
    end
    if action_export_mmd then
      recreate_dir(NamesGiver:GetMmdDir())
    end
  end

  local Chunks
  do
    local listing_pathname = NamesGiver:GetListingPathname()
    export_listing(sourcecode_pathname, listing_pathname)
    Chunks = load_listing(listing_pathname)
  end

  NamesGiver:SetNumItems(#Chunks)

  for chunk_index, Chunk in ipairs(Chunks) do
    local Callgraph = get_callgraph(Chunk)
    if action_export_tgf then
      export_to_tgf(Callgraph, NamesGiver:GetTgfPathname(chunk_index))
    end
    if action_export_dot then
      export_to_dot(Callgraph, NamesGiver:GetDotPathname(chunk_index))
      if action_export_svg then
        dot_to_svg(
          NamesGiver:GetDotPathname(chunk_index),
          NamesGiver:GetSvgPathname(chunk_index)
        )
      end
    end
    if action_export_mmd then
      export_to_mmd(Callgraph, NamesGiver:GetMmdPathname(chunk_index))
    end
  end

  do
    local remove_dir = request('!.file_system.directory.remove')
    if not Wishes.dot then
      remove_dir(NamesGiver:GetDotDir())
    end

    local remove_file = request('!.file_system.file.remove')
    remove_file(NamesGiver:GetListingPathname())
  end

  console_print(')')
end

--[[
  2026 # # # # # # # #
  2026-09-22
]]
