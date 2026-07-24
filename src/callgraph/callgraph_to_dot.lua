-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-24
]]

--[[
  .dot (DAG of tomorrow) is text format for graphs

  It's mentioned at

    https://en.wikipedia.org/wiki/DOT_(graph_description_language)

  and described by "$ man dot" and at

    https://graphviz.org/doc/info/lang.html

  It has expressive syntax and nice for manual editing.

  This implementation uses subgraphs to represent node emitting
  several edges.
]]

-- Imports:
local LinksWriter = request('callgraph_to_dot.LinksWriter')
local add_to_list = request('!.concepts.list.add_item')

local callgraph_to_dot
do
  local OutputStream

  local write =
    function(str)
      OutputStream:Write(str)
    end

  local space = ' '
  local newline = '\010'

  local quote = '"'
  local semicol = ';'
  local equal = '='

  local opening_brace = '{'
  local closing_brace = '}'

  local opening_bracket = '['
  local closing_bracket = ']'

  local kw_strict = 'strict'
  local kw_digraph = 'digraph'
  local kw_label = 'label'

  local start_graph =
    function(graph_name)
      write(kw_strict)
      write(space)
      write(kw_digraph)
      write(space)

      write(quote)
      write(graph_name)
      write(quote)
      write(newline)

      write(opening_brace)
      write(newline)
    end

  local end_graph =
    function()
      write(closing_brace)
      write(newline)
    end

  local set_node_name_format
  local get_node_name
  do
    local node_name_format
    do
      local get_num_digits = request('!.number.get_num_dec_digits')
      local int_to_str = tostring
      set_node_name_format =
        function(num_instructions)
          local num_digits = get_num_digits(num_instructions)
          node_name_format =
            quote .. '%0' .. int_to_str(num_digits) .. 'd' .. quote
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

  local indent = '  '

  local write_label =
    function(name, label)
      write(indent)

      write(name)
      write(space)

      write(opening_bracket)
      write(space)

      write(kw_label)
      write(space)

      write(equal)
      write(space)

      write(quote)
      write(label)
      write(quote)

      write(space)
      write(closing_bracket)

      write(semicol)
      write(newline)
    end

  callgraph_to_dot =
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

      local LinksWriter = LinksWriter.create(OutputStream)

      for src_instruction_index, Instruction in ipairs(InstructionsGraph) do
        local src_name = get_node_name(src_instruction_index)
        local NextOnes = Instruction.NextOnes

        local NextOneNames = { }
        for _, dest_instruction_index in ipairs(NextOnes) do
          add_to_list(NextOneNames, get_node_name(dest_instruction_index))
        end

        LinksWriter:WriteLinks(src_name, NextOneNames)
      end

      end_graph()
    end
end

-- Export:
return callgraph_to_dot

--[[
  2026-07-15
  2026-07-17
  2026-07-23
]]
