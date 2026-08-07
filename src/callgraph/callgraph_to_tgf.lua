-- Serialize processed instructions to graph string in .tgf format

--[[
  Author: Martin Eden
  Last mod.: 2026-08-07
]]

--[[
  .tgf (trivial graph format) is simple and thus nice

  It's described at

    https://en.wikipedia.org/wiki/Trivial_Graph_Format

  This implementation surrounds branching nodes with empty lines.
  We can't do much more for niceness.
]]

local AsciiChars = request('!.concepts.Ascii.Chars')

local callgraph_to_tgf
do
  local IndexSerializer = request('!.concepts.PaddedIndex')
  local OutputStream

  local write_rec
  do
    local field_separator = AsciiChars.space
    local record_separator = AsciiChars.newline
    local list_to_str = request('!.concepts.list.to_string')
    write_rec =
      function(Rec)
        OutputStream:Write(
          list_to_str(Rec, field_separator) .. record_separator
        )
      end
  end

  local write_empty_line =
    function()
      write_rec({ })
    end

  local write_label =
    function(name, label)
      write_rec({ name, label })
    end

  local write_sections_delimiter
  do
    local parts_delim = AsciiChars.number_sign
    write_sections_delimiter =
      function()
        write_rec({ parts_delim })
      end
  end

  local write_link =
    function(src_name, dest_name)
      write_rec({ src_name, dest_name })
    end

  local get_node_name =
    function(index)
      return IndexSerializer:ToString(index)
    end

  callgraph_to_tgf =
    function(InstructionsGraph, Arg_OutputStream)
      IndexSerializer = IndexSerializer.create(#InstructionsGraph)
      OutputStream = Arg_OutputStream

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        write_label(get_node_name(instruction_index), Instruction.label)
      end

      write_empty_line()
      write_sections_delimiter()
      write_empty_line()

      for src_instruction_index, Instruction in ipairs(InstructionsGraph) do
        local src_name = get_node_name(src_instruction_index)
        local NextOnes = Instruction.NextOnes
        local is_forking_node = (#NextOnes > 1)

        if is_forking_node then write_empty_line() end

        for _, dest_instruction_index in ipairs(NextOnes) do
          write_link(src_name, get_node_name(dest_instruction_index))
        end

        if is_forking_node then write_empty_line() end
      end
    end
end

-- Export:
return callgraph_to_tgf

--[[
  2026-07-15
  2026-07-17
  2026-07-23
  2026-07-29
]]
