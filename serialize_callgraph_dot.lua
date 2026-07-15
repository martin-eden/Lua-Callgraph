-- Serialize processed instructions to graph string in .dot format

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

local serialize_callgraph_dot =
  function(InstructionsGraph, OutputStream)
    local num_instructions = #InstructionsGraph

    local get_num_digits = request('!.number.get_num_dec_digits')

    local quote = '"'
    local space = ' '
    local newline = '\010'
    local opening_brace = '{'
    local closing_brace = '}'
    local opening_bracket = '['
    local closing_bracket = ']'
    local equal = '='
    local semicol = ';'
    local arrow = '->'

    index_format =
      quote .. '%' .. '0' .. get_num_digits(num_instructions) .. 'd' .. quote

    OutputStream:Write('digraph CallGraph')
    OutputStream:Write(newline)

    OutputStream:Write(opening_brace)
    OutputStream:Write(newline)

    local indent = '  '

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      OutputStream:Write(indent)

      OutputStream:Write(get_index_str(instruction_index))
      OutputStream:Write(space)

      OutputStream:Write(opening_bracket)
      OutputStream:Write('label')
      OutputStream:Write(equal)
      OutputStream:Write(quote)
      OutputStream:Write(Instruction.label)
      OutputStream:Write(quote)
      OutputStream:Write(closing_bracket)

      OutputStream:Write(semicol)
      OutputStream:Write(newline)
    end

    OutputStream:Write(newline)

    for src_instruction_index, Instruction in ipairs(InstructionsGraph) do
      local NextOnes = Instruction.NextOnes
      for _, dest_instruction_index in ipairs(NextOnes) do
        OutputStream:Write(indent)

        OutputStream:Write(get_index_str(src_instruction_index))
        OutputStream:Write(space)
        OutputStream:Write(arrow)
        OutputStream:Write(space)
        OutputStream:Write(get_index_str(dest_instruction_index))

        OutputStream:Write(newline)
      end
    end

    OutputStream:Write(closing_brace)
    OutputStream:Write(newline)
  end

-- Export:
return serialize_callgraph_dot

--[[
  2026-07-15
]]
