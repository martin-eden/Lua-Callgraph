-- Generate needed names from source file and output dir names

--[[
  Author: Martin Eden
  Last mod.: 2026-07-24
]]

-- Imports:
local create_instance = request('!.table.create_instance')
local get_base_dir = request('get_base_dir')
local get_file_name = request('get_file_name')
local get_padded_number_format = request('get_padded_number_format')

local str_tgf = 'tgf'
local str_dot = 'dot'

local slash = '/'
local dot = '.'

--[[
  Core storage format:

    1 [s] source_code_path_name
    2 [s] output_dir_name
    3 [i] num_items
]]

local DefaultCore =
  { '', '', 0 }

local Methods
Methods =
  {
    create =
      function()
        return create_instance(DefaultCore, Methods)
      end,

    SetSourceName =
      function(Me, source_file_name)
        Me[1] = get_file_name(source_file_name)
      end,

    GetSourceName =
      function(Me)
        return Me[1]
      end,

    SetBaseDir =
      function(Me, output_dir_name)
        Me[2] = get_base_dir(output_dir_name)
      end,

    GetBaseDir =
      function(Me)
        return Me[2]
      end,

    SetNumItems =
      function(Me, num_items)
        Me[3] = num_items
      end,

    GetNumItems =
      function(Me)
        return Me[3]
      end,

    GetTgfDir =
      function(Me)
        return Me:GetBaseDir() .. str_tgf
      end,

    GetDotDir =
      function(Me)
        return Me:GetBaseDir() .. str_dot
      end,

    GetTgfPathnameFormat =
      function(Me)
        return
          Me:GetTgfDir() ..
          slash ..
          Me:GetSourceName() ..
          dot ..
          get_padded_number_format(Me:GetNumItems()) ..
          dot ..
          str_tgf
      end,

    GetDotPathnameFormat =
      function(Me)
        return
          Me:GetDotDir() ..
          slash ..
          Me:GetSourceName() ..
          dot ..
          get_padded_number_format(Me:GetNumItems()) ..
          dot ..
          str_dot
      end,

    GetDotGraphnameFormat =
      function(Me)
        return
          Me:GetSourceName() ..
          dot ..
          get_padded_number_format(Me:GetNumItems())
      end,
  }

-- Export:
return Methods

--[[
  2026-07-23
]]
