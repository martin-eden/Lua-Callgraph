-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-09-14
]]

--[[
  .dot (DAG of tomorrow) is text format for graphs

  It's described at

    https://graphviz.org/doc/info/lang.html

  (and also described by "$ man dot")

  and mentioned at

    https://en.wikipedia.org/wiki/DOT_(graph_description_language)

  It has expressive syntax and nice for manual editing.
]]

--[[
  This implementation merges chains into one .dot statement.
]]

local get_chains
do
  local add_to_list = request('!.concepts.list.add_item')

  get_chains =
    function(InstructionsGraph)
      local num_instructions = #InstructionsGraph

      local Chains = { }

      local VisitedNodes_Map = { }
      for i = 1, num_instructions do
        VisitedNodes_Map[i] = false
      end

      local walk_chain
      walk_chain =
        function(start_node, Chain)
          add_to_list(Chain, start_node)

          if VisitedNodes_Map[start_node] then
            add_to_list(Chains, Chain)
            return
          end

          VisitedNodes_Map[start_node] = true

          local NextOnes = InstructionsGraph[start_node].NextOnes
          local num_next_ones = #NextOnes

          if (num_next_ones == 0) then
            add_to_list(Chains, Chain)
            return
          end

          walk_chain(NextOnes[1], Chain)

          for next_one_index = 2, num_next_ones do
            local InnerChain = { start_node }
            walk_chain(NextOnes[next_one_index], InnerChain)
          end
        end

      for start_node = 1, num_instructions do
        if not VisitedNodes_Map[start_node] then
          walk_chain(start_node, { })
        end
      end

      return Chains
    end
end

local Writer = request('callgraph_to_dot.Writer')

-- Export:
return
  function(InstructionsGraph, OutputStream)
    local Writer = Writer.create(OutputStream, #InstructionsGraph)

    Writer:StartGraph()

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      Writer:Node(instruction_index, Instruction.label)
    end

    Writer:EmptyLine()

    for _, Chain in ipairs(get_chains(InstructionsGraph)) do
      Writer:Chain(Chain)
    end

    Writer:EndGraph()
  end

--[[
  2026 # # # # # # #
  2026-09-13
]]
