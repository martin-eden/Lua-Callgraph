-- .dot elements serialization

--[[
  Author: Martin Eden
  Last mod.: 2026-09-14
]]

--[[
  Internal state

    1 [t] -- output stream instance
    2 [i] -- current line length
    3 [s] -- previous token
    4 [t] -- indent instance
    5 [t] -- padded index instance
]]

local Syntels = request('Syntels')
local Spaces = request('Spaces')

local end_line
local empty_line
do
  local line_separator = Spaces.newline
  end_line =
    function(Me)
      if (Me[2] == 0) then return end

      Me[1]:Write(line_separator)
      Me[2] = 0
      Me[3] = ''
    end

  empty_line =
    function(Me)
      end_line(Me)
      Me[1]:Write(line_separator)
    end
end

local write
do
  local item_separator = Spaces.space
  local sep_len = #item_separator
  local is_alnum = request('!.concepts.Ascii.is_alnum')
  local str_sub = string.sub
  local str_byte = string.byte
  local end_statement = Syntels.end_statement
  local ends_with = request('!.string.ends_with')
  local wrapping_len = 53
  local arrow = Syntels.arrow
  write =
    function(Me, token)
      local OutputStream = Me[1]
      local line_len = Me[2]
      local prev_token = Me[3]

      if (line_len == 0) then
        OutputStream:Write(Me[4]:ToString())
      end

      if
        (line_len > wrapping_len) and
        (
          (prev_token == arrow) or
          (prev_token == end_statement)
        )
      then
        end_line(Me)
        local Indent = Me[4]
        OutputStream:Write(Indent:ToString())
        OutputStream:Write(Indent:GetIndentChunk())
      else
        local write_sep = false

        if (prev_token ~= '') then
          local prev_char_code = str_byte(str_sub(prev_token, -1, -1))
          local next_char_code = str_byte(str_sub(token, 1, 1))
          write_sep =
            -- Separation is strictly needed say between "strict" and "digraph"
            (is_alnum(prev_char_code) and is_alnum(next_char_code)) or
            -- Opportunistically add separation to anything except ";" and " "
            (
              (token ~= end_statement) and
              not ends_with(prev_token, item_separator)
            )
        end

        if write_sep then
          OutputStream:Write(item_separator)
          Me[2] = Me[2] + sep_len
        end
      end

      OutputStream:Write(token)

      Me[2] = Me[2] + #token
      Me[3] = token
    end
end

local end_statement
do
  local end_statement_str = Syntels.end_statement
  end_statement =
    function(Me)
      write(Me, end_statement_str)
      end_line(Me)
    end
end

local arrow
do
  local arrow_str = Syntels.arrow
  arrow =
    function(Me)
      write(Me, arrow_str)
    end
end

local quote
do
  local quote_str = Syntels.quote
  quote =
    function(str)
      return quote_str .. str .. quote_str
    end
end

local get_node_name =
  function(Me, index)
    return quote(Me[5]:ToString(index))
  end

local label
do
  local start_attr = Syntels.start_attr
  local end_attr = Syntels.end_attr
  local label_kw = Syntels.kw_label
  local assign = Syntels.assign
  label =
    function(Me, label)
      write(Me, start_attr)
      write(Me, label_kw)
      write(Me, assign)
      write(Me, quote(label))
      write(Me, end_attr)
    end
end

local StartGraph
do
  local digraph = Syntels.kw_digraph
  local start_graph = Syntels.start_graph
  StartGraph =
    function(Me, graph_name)
      write(Me, digraph)
      if graph_name then
        write(Me, quote(graph_name))
      end
      end_line(Me)
      write(Me, start_graph)
      end_line(Me)
      Me[4]:Inc()
    end
end

local EndGraph
do
  local end_graph = Syntels.end_graph
  EndGraph =
    function(Me)
      Me[4]:Dec()
      end_line(Me)
      write(Me, end_graph)
      end_line(Me)
    end
end

local Node =
  function(Me, index, label_str)
    write(Me, get_node_name(Me, index))
    label(Me, label_str)
    end_statement(Me)
  end

local Chain =
  function(Me, Chain)
    local num_nodes = #Chain
    if (num_nodes <= 1) then return end

    local prev_node = Chain[1]

    write(Me, get_node_name(Me, prev_node))

    for node_idx = 2, num_nodes do
      local next_node = Chain[node_idx]
      arrow(Me)
      write(Me, get_node_name(Me, next_node))
      prev_node = next_node
    end

    end_statement(Me)
  end

local Methods

local create
do
  local attach_methods = request('!.table.attach_methods')
  local indent = '   '
  local Indent = request('!.concepts.Indent')
  local IndexSerializer = request('!.concepts.PaddedIndex')
  create =
    function(Arg_OutputStream, num_nodes)
      OutputStream = Arg_OutputStream

      Indent = Indent.create()
      Indent:SetIndentChunk(indent)

      IndexSerializer = IndexSerializer.create(num_nodes)

      local Core =
        {
          [1] = Arg_OutputStream,
          [2] = 0,
          [3] = '',
          [4] = Indent,
          [5] = IndexSerializer,
        }
      attach_methods(Core, Methods)

      return Core
    end
end

Methods =
  {
    create = create,

    EmptyLine = empty_line,

    StartGraph = StartGraph,
    EndGraph = EndGraph,

    Node = Node,
    Chain = Chain,
  }

-- Export:
return Methods

--[[
  2026 # # # # #
  2026-09-14
]]
