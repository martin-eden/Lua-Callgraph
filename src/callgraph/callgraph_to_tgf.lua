-- Serialize processed instructions to graph string in .tgf format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-29
]]

--[[
  .tgf (trivial graph format) is simple and thus nice

  It's described at

    https://en.wikipedia.org/wiki/Trivial_Graph_Format

  This implementation surrounds branching nodes with empty lines.
  We can't do much more for niceness.
]]

-- Imports:
local Ascii = request('concepts.Ascii')

local callgraph_to_tgf
do
  local OutputStream

  local write_rec
  do
    local field_separator = Ascii.space
    local record_separator = Ascii.newline
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
    local parts_delim = Ascii.number
    write_sections_delimiter =
      function()
        write_rec({ parts_delim })
      end
  end

  local write_link =
    function(src_name, dest_name)
      write_rec({ src_name, dest_name })
    end

  local init_get_node_name
  local get_node_name
  do
    local node_name_format

    do
      local get_num_digits = request('!.number.get_num_dec_digits')
      local int_to_str = tostring
      init_get_node_name =
        function(num_instructions)
          local num_digits = get_num_digits(num_instructions)
          node_name_format = '%0' .. int_to_str(num_digits) .. 'd'
        end
    end
    do
      local str_format = string.format
      get_node_name =
        function(index)
          return str_format(node_name_format, index)
        end
    end
  end

  callgraph_to_tgf =
    function(InstructionsGraph, Arg_OutputStream)
      OutputStream = Arg_OutputStream

      init_get_node_name(#InstructionsGraph)

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
