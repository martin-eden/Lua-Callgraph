-- .dot syntax elements serialization

--[[
  Author: Martin Eden
  Last mod.: 2026-09-02
]]

--[[
  This module exports low-level and high-level serialization routines.

  We export low-level routines because we use LinksWriter.

  We use LinksWriter because we want some structure processing.
  And that structure processing means cognitive load.
  Not for long and simple module.
]]

--[[
  This code also wraps long lines when writing chains.
]]

local Syntels = request('^.concepts.Syntels')
local Spaces = request('^.concepts.Spaces')

local LinksWriter = request('LinksWriter')

local OutputStream

-- Tracking line length for wrapping
local line_len = 0

local write =
  function(str)
    OutputStream:Write(str)
    line_len = line_len + #str
  end

local write_cont
do
  local line_item_separator = Spaces.space
  write_cont =
    function(str)
      write(str)
      write(line_item_separator)
    end
end

local write_final
do
  local line_separator = Spaces.newline
  write_final =
    function(str)
      write(str)
      write(line_separator)
      line_len = 0
    end
end

local write_empty_line =
  function()
    write_final('')
  end

local write_indent
do
  local space = Spaces.space
  local indent = space .. space .. space
  write_indent =
    function()
      write(indent)
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

local start_statement =
  function()
    write_indent()
  end

local end_statement
do
  local end_statement_str = Syntels.end_statement
  end_statement =
    function()
      write_final(end_statement_str)
    end
end

local start_attr
do
  local start_attr_str = Syntels.start_attr
  start_attr =
    function()
      write_cont(start_attr_str)
    end
end

local end_attr
do
  local end_attr_str = Syntels.end_attr
  end_attr =
    function()
      write(end_attr_str)
    end
end

local write_arrow
do
  local wrapping_len = 45
  local arrow = Syntels.arrow
  write_arrow =
    function()
      if (line_len > wrapping_len) then
        write_final(arrow)
        write_indent()
        write_indent()
      else
        write_cont(arrow)
      end
    end
end

local write_label
do
  local label_kw = Syntels.kw_label
  local assign = Syntels.assign
  write_label =
    function(label)
      start_attr()
      write_cont(label_kw)
      write_cont(assign)
      write_cont(label)
      end_attr()
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

local write_node =
  function(name, label)
    start_statement()
    write_cont(quote(name))
    write_label(quote(label))
    end_statement()
  end

local write_subgraph
do
  local start_graph = Syntels.start_graph
  local end_graph = Syntels.end_graph
  write_subgraph =
    function(DestNames)
      write_cont(start_graph)
      for _, dest_name in ipairs(DestNames) do
        write_cont(quote(dest_name))
      end
      write(end_graph)
      end_statement()
    end
end

local Methods
Methods =
  {
    init =
      function(Arg_OutputStream)
        OutputStream = Arg_OutputStream
        LinksWriter.init(Methods)
      end,

    write = write,
    write_cont = write_cont,
    write_final = write_final,

    write_empty_line = write_empty_line,

    quote = quote,

    start_statement = start_statement,
    end_statement = end_statement,
    start_attr = start_attr,
    end_attr = end_attr,
    write_arrow = write_arrow,
    write_label = write_label,

    start_graph = start_graph,
    end_graph = end_graph,

    write_node = write_node,
    write_subgraph = write_subgraph,

    write_links = LinksWriter.write_links,
    done_write_links = LinksWriter.done_write_links,
  }

-- Export:
return Methods

--[[
  2026 # #
  2026-09-02
]]
