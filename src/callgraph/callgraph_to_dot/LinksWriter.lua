-- Writes graph edge links with some intelligence

--[[
  Author: Martin Eden
  Last mod.: 2026-07-24
]]

-- Imports:
local create_instance = request('!.table.create_instance')

local OutputStream

local write =
  function(str)
    OutputStream:Write(str)
  end

local space = ' '
local newline = '\010'

local semicol = ';'

local opening_brace = '{'
local closing_brace = '}'

local arrow = '->'

local indent = '  '

local start_statement =
  function()
    write(indent)
  end

local end_statement =
  function()
    write(semicol)
    write(newline)
  end

local write_prolonger =
  function()
    write(space)
    write(arrow)
    write(space)
  end

--[[
  Core storage format:

    first [s] -- last source node name
    second [s] -- last destination node name
]]

local Core = { first = false, second = false }

local Methods
Methods =
  {
    create =
      function(Arg_OutputStream)
        OutputStream = Arg_OutputStream

        return create_instance(Core, Methods)
      end,

    GetLastDestName =
      function(Me) return Me.second end,

    AddNode =
      function(Me, name)
        if Me.first then
          write(Me.first)
          write_prolonger()
        end
        Me.first, Me.second = Me.second, name
      end,

    Flush =
      function(Me)
        if Me.first then
          write(Me.first)
          write_prolonger()
          write(Me.second)
          end_statement()
        end

        Me.first = false
        Me.second = false
      end,

    WriteLinks =
      function(Me, source_name, DestNames)
        if (#DestNames == 0) then
          Me:Flush()
        elseif (#DestNames == 1) then
          local dest_name = DestNames[1]

          if (source_name == Me:GetLastDestName()) then
            Me:AddNode(dest_name)
          else
            Me:Flush()
            start_statement()
            Me:AddNode(source_name)
            Me:AddNode(dest_name)
          end
        else
          Me:Flush()
          start_statement()
          write(source_name)
          write_prolonger()
          write(opening_brace)
          write(space)
          for _, dest_name in ipairs(DestNames) do
            write(dest_name)
            write(space)
          end
          write(closing_brace)
          end_statement()
        end
      end,
  }

-- Export:
return Methods

--[[
  2026-07-24
]]
