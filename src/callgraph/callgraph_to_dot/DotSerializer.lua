-- Serialize instructions graph to .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-27
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
local Spaces = request('DotSerializer.Spaces')
local Syntels = request('DotSerializer.Syntels')

-- Initialized in create()
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
  local newline = Spaces.newline
  write_final =
    function(str)
      write(str)
      write(newline)
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
      write_cont(strict)
      write_cont(digraph)
      write_final(quote(graph_name))

      write_final(start_graph_str)
    end
end

local end_graph
do
  local end_graph_str = Syntels.end_graph
  end_graph =
    function()
      write_final(end_graph_str)
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

local write_label
do
  local start_attr = Syntels.start_attr
  local end_attr = Syntels.end_attr
  local label_str = Syntels.kw_label
  local assign = Syntels.assign
  local end_statement = Syntels.end_statement
  write_label =
    function(index, label)
      write_indent()
      write_cont(get_node_name(index))
      write_cont(start_attr)
      write_cont(label_str)
      write_cont(assign)
      write_cont(quote(label))
      write(end_attr)
      write_final(end_statement)
    end
end

local LinksWriter = request('DotSerializer.LinksWriter')

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

        Writer.create_write(OutputStream)
        write = Writer.write
        LinksWriter.init(write)

        return Methods
      end,

    start_graph = start_graph,
    end_graph = end_graph,
    write_label = write_label,
    write_links = write_links,
    done_write_links = LinksWriter.done_write_links,
  }

-- Export:
return Methods

--[[
  2026-07-27
]]
