-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-27
]]

-- Imports:
local DotSerializer = request('callgraph_to_dot.DotSerializer')

local callgraph_to_dot
do
  local newline = '\010'

  callgraph_to_dot =
    function(InstructionsGraph, graph_name, OutputStream)
      do
        local num_instructions = #InstructionsGraph
        DotSerializer =
          DotSerializer.create(num_instructions, OutputStream)
      end

      DotSerializer.start_graph(graph_name)

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        DotSerializer.write_label(instruction_index, Instruction.label)
      end

      OutputStream:Write(newline)

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        DotSerializer.write_links(instruction_index, Instruction.NextOnes)
      end
      DotSerializer.done_write_links()

      DotSerializer.end_graph()
    end
end

-- Export:
return callgraph_to_dot

--[[
  2026-07-15
  2026-07-17
  2026-07-23
  2026-07-27
]]
