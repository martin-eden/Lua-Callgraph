-- Wrapper over output stream

--[[
  Author: Martin Eden
  Last mod.: 2026-07-27
]]

--[[
  We want "write(str)" instead of "OutputStream:Write(str)"
]]

local OutputStream

local Methods =
  {
    write =
      function(str)
        if (str == '') then return end
        OutputStream:Write(str)
      end,

    create_write =
      function(Arg_OutputStream)
        OutputStream = Arg_OutputStream
      end,
  }

-- Export:
return Methods

--[[
  2026-07-27
]]
