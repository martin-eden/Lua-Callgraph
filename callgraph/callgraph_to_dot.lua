-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-17
]]

local OutputStream

local space = ' '
local newline = '\010'

local start_graph
local end_graph
do
  local opening_brace = '{'
  local closing_brace = '}'

  start_graph =
    function(graph_name)
      OutputStream:Write('digraph')
      OutputStream:Write(space)
      OutputStream:Write(graph_name)
      OutputStream:Write(newline)

      OutputStream:Write(opening_brace)
      OutputStream:Write(newline)
    end

  end_graph =
    function()
      OutputStream:Write(closing_brace)
      OutputStream:Write(newline)
    end
end

local quote = '"'
local semicol = ';'
local indent = '  '

local write_label
do
  local equal = '='

  local opening_bracket = '['
  local closing_bracket = ']'

  write_label =
    function(name, label)
      OutputStream:Write(indent)

      OutputStream:Write(name)
      OutputStream:Write(space)

      OutputStream:Write(opening_bracket)
      OutputStream:Write('label')
      OutputStream:Write(equal)
      OutputStream:Write(quote)
      OutputStream:Write(label)
      OutputStream:Write(quote)
      OutputStream:Write(closing_bracket)
      OutputStream:Write(semicol)

      OutputStream:Write(newline)
    end
end

local write_link
do
  local arrow = '->'

  write_link =
    function(src_name, dest_name)
      OutputStream:Write(indent)

      OutputStream:Write(src_name)
      OutputStream:Write(space)
      OutputStream:Write(arrow)
      OutputStream:Write(space)
      OutputStream:Write(dest_name)
      OutputStream:Write(semicol)

      OutputStream:Write(newline)
    end
end

local node_name_format

local set_node_name_format
do
  local get_num_digits = request('!.number.get_num_dec_digits')
  local int_to_str = tostring

  set_node_name_format =
    function(num_instructions)
      local num_digits = int_to_str(get_num_digits(num_instructions))

      node_name_format =
        quote .. '%' .. '0' .. num_digits .. 'd' .. quote
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

local callgraph_to_dot =
  function(InstructionsGraph, graph_name, Arg_OutputStream)
    OutputStream = Arg_OutputStream

    local num_instructions = #InstructionsGraph
    set_node_name_format(num_instructions)

    start_graph(graph_name)

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      local name = get_node_name(instruction_index)
      write_label(name, Instruction.label)
    end

    OutputStream:Write(newline)

    for src_instruction_index, Instruction in ipairs(InstructionsGraph) do
      for _, dest_instruction_index in ipairs(Instruction.NextOnes) do
        local src_name = get_node_name(src_instruction_index)
        local dest_name = get_node_name(dest_instruction_index)
        write_link(src_name, dest_name)
      end
    end

    end_graph()
  end

-- Export:
return callgraph_to_dot

--[[
  2026-07-15
  2026-07-17
]]
