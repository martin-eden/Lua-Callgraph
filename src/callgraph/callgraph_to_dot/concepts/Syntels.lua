-- Named syntax elements of .dot format

--[[
  Author: Martin Eden
  Last mod.: 2026-07-31
]]

-- Imports:
local AsciiChars = request('!.concepts.Ascii.Chars')

local Syntels =
  {
    kw_strict = 'strict',
    kw_digraph = 'digraph',
    kw_label = 'label',

    arrow = '->',

    quote = AsciiChars.double_quote,
    assign = AsciiChars.equals,
    end_statement = AsciiChars.semicolon,

    start_graph = AsciiChars.opening_brace,
    end_graph = AsciiChars.closing_brace,

    start_attr = AsciiChars.opening_bracket,
    end_attr = AsciiChars.closing_bracket,
  }

-- Export:
return Syntels

--[[
  2026-07-27
]]
