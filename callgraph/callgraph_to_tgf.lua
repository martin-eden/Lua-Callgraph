-- Serialize processed instructions to graph string in .tgf format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-17
]]

local OutputStream

local write =
  function(str)
    OutputStream:Write(str)
  end

local node_name_format

local set_node_name_format
do
  local get_num_digits = request('!.number.get_num_dec_digits')
  local int_to_str = tostring

  set_node_name_format =
    function(num_instructions)
      local num_digits = get_num_digits(num_instructions)
      node_name_format = '%' .. '0' .. int_to_str(num_digits) .. 'd'
    end
end

local get_node_name
do
  local str_format = string.format

  get_node_name =
    function(index)
      return str_format(node_name_format, index)
    end
end

local space = ' '
local newline = '\010'

local write_label =
  function(name, label)
    write(name)
    write(space)
    write(label)
    write(newline)
  end

local write_sections_delimiter
do
  local parts_delim = '#'

  write_sections_delimiter =
    function()
      write(newline)
      write(parts_delim)
      write(newline)
      write(newline)
    end
end

local write_link =
  function(src_name, dest_name)
    write(src_name)
    write(space)
    write(dest_name)
    write(newline)
  end

local callgraph_to_tgf =
  function(InstructionsGraph, Arg_OutputStream)
    OutputStream = Arg_OutputStream

    do
      local num_instructions = #InstructionsGraph
      set_node_name_format(num_instructions)
    end

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      local name = get_node_name(instruction_index)
      write_label(name, Instruction.label)
    end

    write_sections_delimiter()

    for src_instruction_index, Instruction in ipairs(InstructionsGraph) do
      local NextOnes = Instruction.NextOnes
      local num_next_ones = #NextOnes

      if (num_next_ones > 1) then write(newline) end

      for _, dest_instruction_index in ipairs(NextOnes) do
        local src_name = get_node_name(src_instruction_index)
        local dest_name = get_node_name(dest_instruction_index)
        write_link(src_name, dest_name)
      end

      if (num_next_ones > 1) then write(newline) end
    end
  end

-- Export:
return callgraph_to_tgf

--[[
  2026-07-15
  2026-07-17
]]
