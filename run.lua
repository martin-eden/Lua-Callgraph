-- Create callgraph from Lua function bytecode instructions

--[[
  Author: Martin Eden
  Last mod.: 2026-07-15
]]

package.path = package.path .. ';../../?.lua'
require('workshop.base')

local get_functions =
  function(func)
    local Functions

    local get_functions = request('!.concepts.lua_bytecode_decompiler.parse')

    Functions = get_functions(func)

    return Functions
  end

local create_instruction_rec =
  function()
    return
      {
        label = '',
        NextOnes = { },
      }
  end

local process_function =
  function(Function)
    local Result = { }

    local add_to_list = request('!.concepts.list.add_item')

    for instruction_index, Instruction in ipairs(Function) do
      add_to_list(Result, create_instruction_rec())
    end

    local list_to_str = request('!.concepts.list.to_string')

    for instruction_index, Instruction in ipairs(Function) do
      local instruction_str = list_to_str(Instruction, ' ')

      local ResultRec = Result[instruction_index]

      ResultRec.label = instruction_str
    end

    do
      local opcode_test = 'TEST'
      local opcode_less = 'LT'
      local opcode_less_eq = 'LE'
      local opcode_jump = 'JMP'
      local opcode_equal = 'EQI'
      local opcode_forloop = 'TFORLOOP'

      local num_instructions = #Function

      for instruction_index, Instruction in ipairs(Function) do
        local NextOnes = Result[instruction_index].NextOnes

        local is_last_one = (instruction_index == num_instructions)

        local opcode = Instruction[1]

        local next_instruction_index = instruction_index +  1

        if
          (opcode == opcode_test) or
          (opcode == opcode_less) or
          (opcode == opcode_less_eq) or
          (opcode == opcode_equal)
        then
          add_to_list(NextOnes, next_instruction_index)
          add_to_list(NextOnes, next_instruction_index + 1)
        elseif (opcode == opcode_jump) then
          local jump_offset = tonumber(Instruction[2])

          add_to_list(NextOnes, next_instruction_index + jump_offset)
        elseif (opcode == opcode_forloop) then
          local jump_offset = tonumber(Instruction[3])

          add_to_list(NextOnes, next_instruction_index)
          add_to_list(NextOnes, next_instruction_index - jump_offset)
        else
          if not is_last_one then
            add_to_list(NextOnes, next_instruction_index)
          end
        end
      end
    end

    return Result
  end

-- Main:
do
  local t2s = request('!.convert.value_to_str')

  local func
  do
    -- func = request('!.concepts.lua_bytecode_decompiler.parse.parse_listing')
    -- [[
    func = request('!.concepts.RangesTree.RangesTree.Freetown.get_real_ranges')

    local _
    _, func = debug.getupvalue(func, 3)
    _, func = debug.getupvalue(func, 2)
    --]]
  end

  local Functions = get_functions(func)

  -- print(t2s(Functions))

  local InstructionsGraph = process_function(Functions[1])


  -- print(t2s(InstructionsGraph))

  do
    local serialize_callgraph_tgf = request('serialize_callgraph_tgf')

    local OutputStream
    do
      local OutputFileStream = request('!.concepts.StreamIo.Output.File')
      local file_name = 'callgraph.tgf'

      OutputStream = new(OutputFileStream)
      OutputStream:Open(file_name)
    end

    serialize_callgraph_tgf(InstructionsGraph, OutputStream)

    OutputStream:Close()
  end

  do
    local serialize_callgraph_dot = request('serialize_callgraph_dot')

    local OutputStream
    do
      local OutputFileStream = request('!.concepts.StreamIo.Output.File')
      local file_name = 'callgraph.dot'

      OutputStream = new(OutputFileStream)
      OutputStream:Open(file_name)
    end

    serialize_callgraph_dot(InstructionsGraph, OutputStream)

    OutputStream:Close()
  end
end

--[[
  2026-07-15
]]
