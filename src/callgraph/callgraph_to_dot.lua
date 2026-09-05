-- Serialize processed instructions to graph string in .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-09-05
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
  This implementation uses subgraphs to represent node emitting
  several edges. Also it merges chains into one .dot statement.
]]

local Writer = request('callgraph_to_dot.Writer')
local IndexSerializer = request('!.concepts.PaddedIndex')

local get_node_name =
  function(index)
    return IndexSerializer:ToString(index)
  end

local write_link
do
  local add_to_list = request('!.concepts.list.add_item')
  write_link =
    function(index, NextOnes)
      local NextOneNames = { }
      for _, next_one_index in ipairs(NextOnes) do
        add_to_list(NextOneNames, get_node_name(next_one_index))
      end
      Writer:Link(get_node_name(index), NextOneNames)
    end
end

local serialize_links =
  function(InstructionsGraph)
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

    local ProcessedNodes_Map = { }
    for i = 1, #InstructionsGraph do
      ProcessedNodes_Map[i] = false
    end

    for first_instruction_index = 1, #InstructionsGraph do
      local instruction_index = first_instruction_index
      while true do
        local Instruction = InstructionsGraph[instruction_index]

        if not Instruction then break end
        if ProcessedNodes_Map[instruction_index] then break end

        if (NumInLinks_Map[instruction_index] > 1) then
          Writer:DoneLinks()
        end
        write_link(instruction_index, Instruction.NextOnes)

        ProcessedNodes_Map[instruction_index] = true

        if (#Instruction.NextOnes ~= 1) then break end

        instruction_index = Instruction.NextOnes[1]

        if (NumInLinks_Map[instruction_index] > 1) then break end
      end
    end

    Writer:DoneLinks()
  end

local callgraph_to_dot =
  function(InstructionsGraph, OutputStream)
    Writer = Writer.create(OutputStream)
    IndexSerializer = IndexSerializer.create(#InstructionsGraph)

    Writer:StartGraph()

    for instruction_index, Instruction in ipairs(InstructionsGraph) do
      Writer:Node(get_node_name(instruction_index), Instruction.label)
    end

    Writer:EmptyLine()

    serialize_links(InstructionsGraph)

    Writer:EndGraph()
  end

-- Export:
return callgraph_to_dot

--[[
  2026 # # # # # #
  2026-09-03
]]
