-- Named syntax elements of .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-31
]]

-- Imports:
local Ascii = request('^.^.^.concepts.Ascii')

local Syntels =
  {
    kw_strict = 'strict',
    kw_digraph = 'digraph',
    kw_label = 'label',

    arrow = '->',

    quote = Ascii.quote,
    assign = Ascii.equal,
    end_statement = Ascii.semicol,

    start_graph = Ascii.opening_brace,
    end_graph = Ascii.closing_brace,

    start_attr = Ascii.opening_bracket,
    end_attr = Ascii.closing_bracket,
  }

-- Export:
return Syntels

--[[
  2026-07-27
]]
