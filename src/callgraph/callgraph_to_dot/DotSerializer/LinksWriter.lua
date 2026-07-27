-- Writes graph edge links with some intelligence

--[[
  Author: Martin Eden
  Last mod.: 2026-07-27
]]

--[[
  Main function is WriteLinks() and it's called with arguments like

    '11' { '12' }
    '12' { '13' }
    '13' { '14' '15' }

  It does two smart things:

    * Detects chains and writes them compactly:

      > "11" -> "12" - "13";

    * Uses subgraphs if profitable:

      > "13" -> { "14" "15" };
]]

-- Imports:
local Spaces = request('Spaces')
local Syntels = request('Syntels')

-- Initialized in init()
local write

local write_indent
do
  local indent = Spaces.indent
  write_indent =
    function()
      write(indent)
    end
end

local write_cont
do
  local space = Spaces.space
  write_cont =
    function(str)
      write(str)
      write(space)
    end
end

local write_final
do
  local end_statement_str = Syntels.end_statement
  local newline = Spaces.newline
  write_final =
    function(str)
      write(str)
      write(end_statement_str)
      write(newline)
    end
end

local write_arrow
do
  local arrow = Syntels.arrow
  write_arrow =
    function()
      write_cont(arrow)
    end
end

local write_subgraph
do
  local start_graph = Syntels.start_graph
  local end_graph = Syntels.end_graph
  write_subgraph =
    function(DestNames)
      write_cont(start_graph)
      for _, dest_name in ipairs(DestNames) do
        write_cont(dest_name)
      end
      write_final(end_graph)
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
      write_cont(Queue[1])
      write_arrow()
    end
    Queue[1], Queue[2] = Queue[2], name
  end

local queue_flush =
  function()
    if Queue[1] then
      write_cont(Queue[1])
      write_arrow()
      write_final(Queue[2])
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
        write_indent()
        queue_add(source_name)
        queue_add(dest_name)
      end
    else
      queue_flush()
      write_indent()
      write_cont(source_name)
      write_arrow()
      write_subgraph(DestNames)
    end
  end

local Interface =
  {
    init =
      function(write_func)
        write = write_func
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
