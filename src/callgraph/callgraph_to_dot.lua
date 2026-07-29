-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-29
]]

-- Imports:
local DotSerializer = request('callgraph_to_dot.DotSerializer')

local serialize_links
do
  serialize_links =
    function(InstructionsGraph)
      --[[
        For simplicity we can just call write_links() in cycle.
        It serializes chains nicely. But we want to break chain
        if node is referenced more than once.

        That's why we have this function.
      ]]

      local NumInLinks_Map = { }

      for instruction_index in ipairs(InstructionsGraph) do
        NumInLinks_Map[instruction_index] = 0
      end
      NumInLinks_Map[1] = 1

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        for _, next_one_index in ipairs(Instruction.NextOnes) do
          NumInLinks_Map[next_one_index] = NumInLinks_Map[next_one_index] + 1
        end
      end

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        if (NumInLinks_Map[instruction_index] > 1) then
          DotSerializer.done_write_links()
        end
        DotSerializer.write_links(instruction_index, Instruction.NextOnes)
      end
      DotSerializer.done_write_links()
    end
end

local callgraph_to_dot =
  function(InstructionsGraph, graph_name, OutputStream)
    DotSerializer =
      DotSerializer.create(#InstructionsGraph, OutputStream)

    DotSerializer.start_graph(graph_name)

    serialize_links(InstructionsGraph)

    DotSerializer.write_empty_line()

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      DotSerializer.write_node(instruction_index, Instruction.label)
    end

    DotSerializer.end_graph()
  end

-- Export:
return callgraph_to_dot

--[[
  2026-07-15
  2026-07-17
  2026-07-23
  2026-07-27
  2026-07-29
]]
