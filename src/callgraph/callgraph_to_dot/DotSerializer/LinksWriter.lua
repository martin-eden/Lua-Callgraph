-- Writes graph edge links with some intelligence

--[[
  Author: Martin Eden
  Last mod.: 2026-07-28
]]

--[[
  Main function is WriteLinks() and it's called with arguments like

    '11' { '12' }
    '12' { '13' }
    '13' { '14' '15' }

  It does two smart things:

    * Detects chains and writes them compactly
    * Uses subgraphs if profitable

    > "11" -> "12" - "13" -> { "14" "15" };
]]

-- Imports:
local Syntels = request('Syntels')

-- Set in init()
local Writer

local write_subgraph
do
  local start_graph = Syntels.start_graph
  local end_graph = Syntels.end_graph
  write_subgraph =
    function(DestNames)
      Writer.write_cont(start_graph)
      for _, dest_name in ipairs(DestNames) do
        Writer.write_cont(dest_name)
      end
      Writer.write(end_graph)
      Writer.end_statement()
    end
end

--[[
  Queue storage format:

    1 [s] -- last source node name
    2 [s] -- last destination node name
]]

local Queue = { [1] = false, [2] = false }

local queue_add =
  function(name)
    if Queue[1] then
      Writer.write_cont(Queue[1])
      Writer.write_arrow()
    end
    Queue[1], Queue[2] = Queue[2], name
  end

local queue_flush =
  function()
    if Queue[1] then
      Writer.write_cont(Queue[1])
      Writer.write_arrow()
      Writer.write(Queue[2])
      Writer.end_statement()
    end
    Queue[1], Queue[2] = false, false
  end

local write_links =
  function(source_name, DestNames)
    if (#DestNames == 0) then
      queue_flush()
    elseif (#DestNames == 1) then
      local dest_name = DestNames[1]

      if (source_name == Queue[2]) then
        queue_add(dest_name)
      else
        queue_flush()
        Writer.start_statement()
        queue_add(source_name)
        queue_add(dest_name)
      end
    else
      if (source_name == Queue[2]) then
        Writer.write_cont(Queue[1])
        Writer.write_arrow()
        Writer.write_cont(Queue[2])
        Writer.write_arrow()
        Queue[1], Queue[2] = false, false
        write_subgraph(DestNames)
      else
        queue_flush()
        Writer.start_statement()
        Writer.write_cont(source_name)
        Writer.write_arrow()
        write_subgraph(DestNames)
      end
    end
  end

local Interface =
  {
    init =
      function(Arg_Writer)
        Writer = Arg_Writer
      end,
    write_links = write_links,
    done_write_links = queue_flush,
  }

-- Export:
return Interface

--[[
  2026-07-24
  2026-07-27
]]
