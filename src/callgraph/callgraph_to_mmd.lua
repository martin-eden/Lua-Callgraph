-- Serialize processed instructions to graph in .mmd (mermaid) format

--[[
  Author: Martin Eden
  Last mod.: 2026-09-15
]]

local Writer = request('callgraph_to_mmd.Writer')
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
  2026-09-15
]]
