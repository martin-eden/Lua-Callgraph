-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-23
]]

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

  local arrow = '->'

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

  local write_link =
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

      for src_instruction_index, Instruction in ipairs(InstructionsGraph) do
        -- Implementation surrounds branch nodes with empty lines

        local NextOnes = Instruction.NextOnes
        local is_branch_node = (#NextOnes > 1)

        if is_branch_node then write(newline) end

        for _, dest_instruction_index in ipairs(NextOnes) do
          local src_name = get_node_name(src_instruction_index)
          local dest_name = get_node_name(dest_instruction_index)
          write_link(src_name, dest_name)
        end

        if is_branch_node then write(newline) end
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
