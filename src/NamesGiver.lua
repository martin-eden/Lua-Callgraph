-- Generate needed names from source file and output dir names

--[[
  Author: Martin Eden
  Last mod.: 2026-09-08
]]

--[[
  Core storage format:

    1 [t] output directory path names
    2 [t] PaddedIndex which depends from number of items
]]

local pathname_from_str = request('!.concepts.path_name.pathname_from_str')
local pathname_to_str = request('!.concepts.path_name.pathname_to_str')
local list_to_str = request('!.concepts.list.to_string')

local get_output_dir =
  function(Me)
    return pathname_to_str(Me[1])
  end

local set_output_dir =
  function(Me, output_dir_name)
    Me[1] = pathname_from_str(output_dir_name)
  end

local set_num_items
do
  local PaddedIndex = request('!.concepts.PaddedIndex')
  set_num_items =
    function(Me, num_items)
      Me[2] = PaddedIndex.create(num_items)
    end
end

local represent_index =
  function(Me, index)
    return Me[2]:ToString(index)
  end

local get_tgf_dir
local get_dot_dir
local get_svg_dir
local get_tgf_pathname
local get_dot_pathname
local get_dot_graphname
local get_svg_pathname
do
  local get_custom_name =
    function(Me, name)
      return pathname_to_str({ get_output_dir(Me), name })
    end

  local name_delimiter = request('!.concepts.Ascii.Chars').dot
  local format_tgf = 'tgf'
  local format_dot = 'dot'
  local format_svg = 'svg'
  local listing_filename = 'listing.is'

  get_tgf_dir =
    function(Me)
      return get_custom_name(Me, format_tgf)
    end

  get_dot_dir =
    function(Me)
      return get_custom_name(Me, format_dot)
    end

  get_svg_dir =
    function(Me)
      return get_custom_name(Me, format_svg)
    end

  get_listing_pathname =
    function(Me)
      return get_custom_name(Me, listing_filename)
    end

  get_tgf_pathname =
    function(Me, index)
      return
        pathname_to_str(
          {
            get_tgf_dir(Me),
            list_to_str(
              { represent_index(Me, index), format_tgf },
              name_delimiter
            ),
          }
        )
    end

  get_dot_pathname =
    function(Me, index)
      return
        pathname_to_str(
          {
            get_dot_dir(Me),
            list_to_str(
              { represent_index(Me, index), format_dot },
              name_delimiter
            ),
          }
        )
    end

  get_svg_pathname =
    function(Me, index)
      return
        pathname_to_str(
          {
            get_svg_dir(Me),
            list_to_str(
              { represent_index(Me, index), format_svg },
              name_delimiter
            ),
          }
        )
    end
end

local Methods
do
  local create
  do
    local create_instance = request('!.table.create_instance')
    create =
      function()
        -- Allocate data slots. Data setup is done via methods
        local Core = { [1] = false, [2] = false }

        return create_instance(Core, Methods)
      end
  end

  Methods =
    {
      create = create,

      SetOutputDir = set_output_dir,
      SetNumItems = set_num_items,

      GetOutputDir = get_output_dir,
      GetTgfDir = get_tgf_dir,
      GetDotDir = get_dot_dir,
      GetSvgDir = get_svg_dir,

      GetListingPathname = get_listing_pathname,
      GetTgfPathname = get_tgf_pathname,
      GetDotPathname = get_dot_pathname,
      GetSvgPathname = get_svg_pathname,
    }
end

-- Export:
return Methods

--[[
  2026 # # # # #
  2026-09-08
]]
