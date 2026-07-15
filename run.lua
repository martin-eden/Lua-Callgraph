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
      local opcode_equal_reg = 'EQ'
      local opcode_equal_const = 'EQI'
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
          (opcode == opcode_equal_reg) or
          (opcode == opcode_equal_const)
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

local export_to_tgf
local export_to_dot

do
  local OutputFileStream = request('!.concepts.StreamIo.Output.File')

  local callgraph_to_tgf = request('callgraph.callgraph_to_tgf')

  export_to_tgf =
    function(InstructionsGraph, file_name)
      local OutputStream = new(OutputFileStream)

      OutputStream:Open(file_name)

      callgraph_to_tgf(InstructionsGraph, OutputStream)

      OutputStream:Close()
    end

  local callgraph_to_dot = request('callgraph.callgraph_to_dot')

  export_to_dot =
    function(InstructionsGraph, file_name)
      local OutputStream = new(OutputFileStream)

      OutputStream:Open(file_name)

      callgraph_to_dot(InstructionsGraph, OutputStream)

      OutputStream:Close()
    end
end

local Config =
  {
    source_code_file_name = arg[1],
  }

local print_help =
  function()
    print(
      '\n' ..
      'Creates call graphs for Lua code.' .. '\n' ..
      '\n' ..
      'Usage: <lua_file_name>' .. '\n' ..
      '\n' ..
      'Writes results to ./output/ .' .. '\n' ..
      '\n' ..
      '-- Martin, 2026-07' .. '\n'
    )
  end

-- Main:
do
  -- local t2s = request('!.convert.value_to_str')

  local source_code_str
  do
    local file_to_str = request('!.convert.file_to_str')

    local source_code_file_name = Config.source_code_file_name

    if not source_code_file_name then
      print_help()
      return
    end

    source_code_str = file_to_str(source_code_file_name)
  end

  local get_bytecode =
    request('!.concepts.lua_bytecode_decompiler.bytecode_from_source')
  local get_listing =
    request('!.concepts.lua_bytecode_decompiler.listing_from_bytecode')

  local bytecode = get_bytecode(source_code_str)

  local Functions = get_listing(bytecode)

  -- print(t2s(Functions))

  local tgf_name_format = 'output/callgraph_%d.tgf'
  local dot_name_format = 'output/callgraph_%d.dot'

  local str_format = string.format

  for function_index, Function in ipairs(Functions) do
    local InstructionsGraph = process_function(Functions[function_index])

    -- print(t2s(InstructionsGraph))

    local tgf_file_name = str_format(tgf_name_format, function_index)
    export_to_tgf(InstructionsGraph, tgf_file_name)

    local dot_file_name = str_format(dot_name_format, function_index)
    export_to_dot(InstructionsGraph, dot_file_name)
  end
end

--[[
  2026-07-15
]]
