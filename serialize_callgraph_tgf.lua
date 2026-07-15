-- Serialize processed instructions to graph string in .tgf format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-15
]]

local index_format = ''

local str_format = string.format

local get_index_str =
  function(index)
    return str_format(index_format, index)
  end

local serialize_callgraph_tgf =
  function(InstructionsGraph, OutputStream)
    local num_instructions = #InstructionsGraph

    local get_num_digits = request('!.number.get_num_dec_digits')

    index_format = '%' .. '0' .. get_num_digits(num_instructions) .. 'd'

    local space = ' '
    local newline = '\010'

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      OutputStream:Write(get_index_str(instruction_index))
      OutputStream:Write(space)
      OutputStream:Write(Instruction.label)
      OutputStream:Write(newline)
    end

    local parts_delim = '#'

    OutputStream:Write(parts_delim)
    OutputStream:Write(newline)

    for src_instruction_index, Instruction in ipairs(InstructionsGraph) do
      local NextOnes = Instruction.NextOnes
      for _, dest_instruction_index in ipairs(NextOnes) do
        OutputStream:Write(get_index_str(src_instruction_index))
        OutputStream:Write(space)
        OutputStream:Write(get_index_str(dest_instruction_index))
        OutputStream:Write(newline)
      end
    end
  end

-- Export:
return serialize_callgraph_tgf

--[[
  2026-07-15
]]
