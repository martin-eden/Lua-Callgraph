-- Writes graph edge links with some intelligence

--[[
  Author: Martin Eden
  Last mod.: 2026-09-02
]]

--[[
  Main function is write_links() and it's called with arguments like

    '11' { '12' }
    '12' { '13' }
    '13' { '14' '15' }

  It does two smart things:

    * Detects chains and writes them compactly
    * Uses subgraphs if profitable

    > "11" -> "12" - "13" -> { "14" "15" };
]]

-- Imports:
local Syntels = request('^.concepts.Syntels')

-- Set in init()
local Writer

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
    source_name = Writer.quote(source_name)
    if (#DestNames == 0) then
      queue_flush()
    elseif (#DestNames == 1) then
      local dest_name = Writer.quote(DestNames[1])

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
        Writer.write_subgraph(DestNames)
      else
        queue_flush()
        Writer.start_statement()
        Writer.write_cont(source_name)
        Writer.write_arrow()
        Writer.write_subgraph(DestNames)
      end
    end
  end

-- Export:
return
  {
    init =
      function(Arg_Writer)
        Writer = Arg_Writer
      end,
    write_links = write_links,
    done_write_links = queue_flush,
  }

--[[
  2026 # #
  2026-09-02
]]
