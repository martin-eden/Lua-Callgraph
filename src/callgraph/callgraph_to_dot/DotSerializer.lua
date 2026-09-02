-- Serialize instructions graph to .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-09-02
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

local Methods

local IndexSerializer
local Writer

local create
do
  IndexSerializer = request('!.concepts.PaddedIndex')
  Writer = request('mechs.Writer')

  create =
    function(num_instructions, OutputStream)
      IndexSerializer = IndexSerializer.create(num_instructions)
      Writer.init(OutputStream)

      return Methods
    end
end

local get_node_name =
  function(index)
    return IndexSerializer:ToString(index)
  end

local write_node =
  function(index, label)
    Writer.write_node(get_node_name(index), label)
  end

local write_links
do
  local add_to_list = request('!.concepts.list.add_item')
  write_links =
    function(index, NextOnes)
      local NextOneNames = { }
      for _, next_one_index in ipairs(NextOnes) do
        add_to_list(NextOneNames, get_node_name(next_one_index))
      end
      Writer.write_links(get_node_name(index), NextOneNames)
    end
end

Methods =
  {
    create = create,

    write_empty_line = Writer.write_empty_line,
    start_graph = Writer.start_graph,
    end_graph = Writer.end_graph,
    write_node = write_node,
    write_links = write_links,
    done_write_links = Writer.done_write_links,
  }

-- Export:
return Methods

--[[
  2026-07-27
]]
