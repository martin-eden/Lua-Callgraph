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

local Writer = request('callgraph_to_dot.Writer')
local get_chains = request('get_chains')

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
