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
local Writer = request('DotSerializer.Writer')
local Syntels = request('DotSerializer.Syntels')
local LinksWriter = request('DotSerializer.LinksWriter')

local write_label
do
  local label_kw = Syntels.kw_label
  local assign = Syntels.assign
  write_label =
    function(label)
      Writer.start_attr()
      Writer.write_cont(label_kw)
      Writer.write_cont(assign)
      Writer.write_cont(label)
      Writer.end_attr()
    end
end

local quote
do
  local quote_char = Syntels.quote
  quote =
    function(str)
      return quote_char .. str .. quote_char
    end
end

local start_graph
do
  local strict = Syntels.kw_strict
  local digraph = Syntels.kw_digraph
  local start_graph_str = Syntels.start_graph
  start_graph =
    function(graph_name)
      Writer.write_cont(strict)
      Writer.write_cont(digraph)
      Writer.write_final(quote(graph_name))
      Writer.write_final(start_graph_str)
    end
end

local end_graph
do
  local end_graph_str = Syntels.end_graph
  end_graph =
    function()
      Writer.write_final(end_graph_str)
    end
end

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
          quote('%0' .. int_to_str(get_num_digits(max_index)) .. 'd')
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
    Writer.start_statement()
    Writer.write_cont(get_node_name(index))
    write_label(quote(label))
    Writer.end_statement()
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
      LinksWriter.write_links(get_node_name(index), NextOneNames)
    end
end

local Methods
Methods =
  {
    create =
      function(num_instructions, OutputStream)
        init_get_node_name(num_instructions)

        Writer.init(OutputStream)
        LinksWriter.init(Writer)

        return Methods
      end,

    start_graph = start_graph,
    end_graph = end_graph,
    write_node = write_node,
    write_links = write_links,
    done_write_links = LinksWriter.done_write_links,
  }

-- Export:
return Methods

--[[
  2026-07-27
]]
