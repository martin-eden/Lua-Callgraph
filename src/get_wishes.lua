-- Parse string to map of words and intersect with another wordmap

--[[
  Author: Martin Eden
  Last mod.: 2026-09-22
]]

--[[
  Output
    [t] -- map of words

  Input
    1 [s] -- string with space-separated words
    2 [t] -- list of valid words
    3 [t] -- behavior
      explode_on_unknown [b] -- raise error on unknown words
      empty_means_all [b] -- return map of valid words
        when no known words found
]]

local get_words = request('!.concepts.words.from_string')
local map_values = request('!.table.map_values')
local subtract = request('!.table.subtract')
local intersect = request('!.table.intersect')
local is_empty = request('!.table.is_empty')

return
  function(wishes_str, ValidWishes, Config)
    local empty_means_all = Config.empty_means_all
    local explode_on_unknown = Config.explode_on_unknown

    local Wishmap
    do
      Wishmap = map_values(get_words(wishes_str))

      local Validmap = map_values(ValidWishes)

      if explode_on_unknown then
        local Remains = new(Wishmap)
        subtract(Remains, Validmap)

        if not is_empty(Remains) then
          error('Unknown token.')
        end
      end

      intersect(Wishmap, Validmap)

      if empty_means_all then
        if is_empty(Wishmap) then
          Wishmap = Validmap
        end
      end
    end

    return Wishmap
  end

--[[
  2026-09-22
]]
