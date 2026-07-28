-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-28
]]

-- Imports:
local DotSerializer = request('callgraph_to_dot.DotSerializer')

local serialize_links
do
  serialize_links =
    function(InstructionsGraph)
      local NumInLinks_Map = { }

      for instruction_index in ipairs(InstructionsGraph) do
        NumInLinks_Map[instruction_index] = 0
      end
      NumInLinks_Map[1] = 1

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        local NextOnes = Instruction.NextOnes
        for _, next_one_index in ipairs(NextOnes) do
          local num_in_links = NumInLinks_Map[next_one_index] or 0
          num_in_links = num_in_links + 1
          NumInLinks_Map[next_one_index] = num_in_links
        end
      end

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        local NextOnes = Instruction.NextOnes
        if (#NextOnes == 0) then goto next end
        if (NumInLinks_Map[instruction_index] > 1) then
          DotSerializer.done_write_links()
        end
        DotSerializer.write_links(instruction_index, NextOnes)
        :: next ::
      end
      DotSerializer.done_write_links()
    end
end

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

      serialize_links(InstructionsGraph)

      OutputStream:Write(newline)

      for instruction_index, Instruction in ipairs(InstructionsGraph) do
        DotSerializer.write_node(instruction_index, Instruction.label)
      end

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
