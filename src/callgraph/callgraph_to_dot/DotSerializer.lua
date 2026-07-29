-- Serialize instructions graph to .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-28
]]

--[[
  .dot (DAG of tomorrow) is text format for graphs

  It's mentioned at

    https://en.wikipedia.org/wiki/DOT_(graph_description_language)

  and described by "$ man dot" and at

    https://graphviz.org/doc/info/lang.html

  It has expressive syntax and nice for manual editing.

  This implementation uses subgraphs to represent node emitting
  several edges. Also it merges chains into one .dot statement.
]]

-- Imports:
local Writer = request('mechs.Writer')

local init_get_node_name
local get_node_name
do
  local node_name_format
  do
    local get_num_digits = request('!.number.get_num_dec_digits')
    local int_to_str = tostring
    init_get_node_name =
      function(max_index)
        node_name_format =
          '%0' .. int_to_str(get_num_digits(max_index)) .. 'd'
      end
  end
  do
    local str_format = string.format
    get_node_name =
      function(index)
        return str_format(node_name_format, index)
      end
  end
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

local Methods
Methods =
  {
    create =
      function(num_instructions, OutputStream)
        init_get_node_name(num_instructions)
        Writer.init(OutputStream)

        return Methods
      end,

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
