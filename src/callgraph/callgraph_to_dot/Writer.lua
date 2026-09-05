-- .dot syntax elements serialization

--[[
  Author: Martin Eden
  Last mod.: 2026-09-05
]]

--[[
  Contract

  Basically contract is the same as for our Lua table serializer:
  output will only contain tokens you asked us to write and
  whitespaces we've added between them as we please.

  But we can have internal state and we may export whitespace-writing
  methods.

  We may also export convenience methods as write_links() that
  write more than one token per call.
]]

--[[
  Internal state

    1 [t] -- output stream instance
    2 [i] -- current line length
    3 [s] -- previous token
    4 [t] -- indent instance
]]

local Syntels = request('Syntels')
local Spaces = request('Spaces')

local LinksWriter = request('LinksWriter')

local EndLine
local EmptyLine
do
  local line_separator = Spaces.newline
  EndLine =
    function(Me)
      if (Me[2] == 0) then return end

      Me[1]:Write(line_separator)
      Me[2] = 0
      Me[3] = ''
    end

  EmptyLine =
    function(Me)
      Me:EndLine()
      Me[1]:Write(line_separator)
    end
end

local Write
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
  Write =
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
        Me:EndLine()
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

local EndStatement
do
  local end_statement = Syntels.end_statement
  EndStatement =
    function(Me)
      Me:Write(end_statement)
      Me:EndLine()
    end
end

local Arrow
do
  local arrow = Syntels.arrow
  Arrow =
    function(Me)
      Me:Write(arrow)
    end
end

local quote = request('quote')

local Label
do
  local start_attr = Syntels.start_attr
  local end_attr = Syntels.end_attr
  local label_kw = Syntels.kw_label
  local assign = Syntels.assign
  Label =
    function(Me, label)
      Me:Write(start_attr)
      Me:Write(label_kw)
      Me:Write(assign)
      Me:Write(quote(label))
      Me:Write(end_attr)
    end
end

local StartGraph
do
  local digraph = Syntels.kw_digraph
  local start_graph = Syntels.start_graph
  StartGraph =
    function(Me, graph_name)
      Me:Write(digraph)
      if graph_name then
        Me:Write(quote(graph_name))
      end
      Me:EndLine()
      Me:Write(start_graph)
      Me:EndLine()
      Me[4]:Inc()
    end
end

local EndGraph
do
  local end_graph = Syntels.end_graph
  EndGraph =
    function(Me)
      Me[4]:Dec()
      Me:EndLine()
      Me:Write(end_graph)
      Me:EndLine()
    end
end

local Node =
  function(Me, name, label)
    Me:Write(quote(name))
    Me:Label(label)
    Me:EndStatement()
  end

local Subgraph
do
  local start_graph = Syntels.start_graph
  local end_graph = Syntels.end_graph
  Subgraph =
    function(Me, DestNames)
      Me:Write(start_graph)
      for _, dest_name in ipairs(DestNames) do
        Me:Write(quote(dest_name))
      end
      Me:Write(end_graph)
    end
end

local Methods

local create
do
  local attach_methods = request('!.table.attach_methods')
  local indent = '   '
  local Indent = request('!.concepts.Indent')
  create =
    function(Arg_OutputStream)
      OutputStream = Arg_OutputStream

      Indent = Indent.create()
      Indent:SetIndentChunk(indent)

      local Core =
        {
          [1] = Arg_OutputStream,
          [2] = 0,
          [3] = '',
          [4] = Indent,
        }
      attach_methods(Core, Methods)

      return Core
    end
end

Methods =
  {
    create = create,

    Write = Write,
    EndLine = EndLine,

    EmptyLine = EmptyLine,

    EndStatement = EndStatement,

    Arrow = Arrow,
    Label = Label,

    StartGraph = StartGraph,
    EndGraph = EndGraph,

    Node = Node,
    Subgraph = Subgraph,

    Link = LinksWriter.Link,
    DoneLinks = LinksWriter.DoneLinks,
  }

-- Export:
return Methods

--[[
  2026 # # # #
  2026-09-05
]]
