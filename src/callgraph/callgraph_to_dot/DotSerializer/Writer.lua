-- Syntax elements serialization

--[[
  Author: Martin Eden
  Last mod.: 2026-07-28
]]

--[[
  This code also wraps long lines when writing chains.
]]

-- Imports:
local Spaces = request('Spaces')
local Syntels = request('Syntels')

local OutputStream

-- Tracking line length for wrapping
local line_len = 0

local write =
  function(str)
    if (str == '') then return end
    OutputStream:Write(str)
    line_len = line_len + #str
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
      line_len = 0
    end
end

local write_indent
do
  local indent = Spaces.indent
  write_indent =
    function()
      write(indent)
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

local Methods =
  {
    init =
      function(Arg_OutputStream)
        OutputStream = Arg_OutputStream
      end,

    write = write,
    write_cont = write_cont,
    write_final = write_final,
    start_statement = start_statement,
    end_statement = end_statement,
    start_attr = start_attr,
    end_attr = end_attr,
    write_arrow = write_arrow,
  }

-- Export:
return Methods

--[[
  2026-07-27
  2026-07-28
]]
