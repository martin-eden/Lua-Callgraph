-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-17
]]

local OutputStream

local write =
  function(str)
    OutputStream:Write(str)
  end

local newline = '\010'
local space = ' '

local start_graph
local end_graph
do
  local opening_brace = '{'
  local closing_brace = '}'

  start_graph =
    function(graph_name)
      write('digraph')
      write(space)
      write(graph_name)
      write(newline)

      write(opening_brace)
      write(newline)
    end

  end_graph =
    function()
      write(closing_brace)
      write(newline)
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
      write(indent)

      write(name)
      write(space)

      write(opening_bracket)
      write('label')
      write(equal)
      write(quote)
      write(label)
      write(quote)
      write(closing_bracket)

      write(semicol)
      write(newline)
    end
end

local write_link
do
  local arrow = '->'

  write_link =
    function(src_name, dest_name)
      write(indent)

      write(src_name)
      write(space)
      write(arrow)
      write(space)
      write(dest_name)

      write(semicol)
      write(newline)
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

    do
      local num_instructions = #InstructionsGraph
      set_node_name_format(num_instructions)
    end

    start_graph(graph_name)

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      local name = get_node_name(instruction_index)
      write_label(name, Instruction.label)
    end

    write(newline)

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

    end_graph()
  end

-- Export:
return callgraph_to_dot

--[[
  2026-07-15
  2026-07-17
]]
