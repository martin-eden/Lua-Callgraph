-- Writes graph edge links with some intelligence

--[[
  Author: Martin Eden
  Last mod.: 2026-09-05
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
local Syntels = request('Syntels')

--[[
  Queue storage format:

    1 [s] -- last source node name
    2 [s] -- last destination node name
]]

local Queue = { [1] = false, [2] = false }

local queue_add =
  function(Me, name)
    if Queue[1] then
      Me:Write(Queue[1])
      Me:Arrow()
    end
    Queue[1], Queue[2] = Queue[2], name
  end

local queue_flush =
  function(Me)
    if Queue[1] then
      Me:Write(Queue[1])
      Me:Arrow()
      Me:Write(Queue[2])
      Me:EndStatement()
    end
    Queue[1], Queue[2] = false, false
  end

local quote = request('quote')

local Link =
  function(Me, source_name, DestNames)
    source_name = quote(source_name)
    if (#DestNames == 0) then
      queue_flush(Me)
    elseif (#DestNames == 1) then
      local dest_name = quote(DestNames[1])

      if (source_name == Queue[2]) then
        queue_add(Me, dest_name)
      else
        queue_flush(Me)
        queue_add(Me, source_name)
        queue_add(Me, dest_name)
      end
    else
      if (source_name == Queue[2]) then
        Me:Write(Queue[1])
        Me:Arrow()
        Me:Write(Queue[2])
        Queue[1], Queue[2] = false, false
      else
        queue_flush(Me)
        Me:Write(source_name)
      end
      Me:Arrow()
      Me:Subgraph(DestNames)
      Me:EndStatement()
    end
  end

-- Export:
return
  {
    Link = Link,
    DoneLinks = queue_flush,
  }

--[[
  2026 # #
  2026-09-02
]]
