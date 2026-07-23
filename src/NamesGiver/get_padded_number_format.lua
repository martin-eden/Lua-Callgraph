-- Return format string like "%02d" when <num_items> is in [10, 99]

--[[
  Author: Martin Eden
  Last mod.: 2026-07-23
]]

-- Imports:
local get_num_digits = request('!.number.get_num_dec_digits')
local int_to_str = tostring

local get_padded_number_format =
  function(num_items)
    local num_digits = get_num_digits(num_items)

    return '%0' .. int_to_str(num_digits) .. 'd'
  end

-- Export:
return get_padded_number_format

--[[
  2026-07-23
]]
