package.preload['get_wishes'] =
  function(...)
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
  end
package.preload['NamesGiver'] =
  function(...)
    local pathname_from_str =
      request('!.concepts.path_name.pathname_from_str')
    local pathname_to_str =
      request('!.concepts.path_name.pathname_to_str')
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
      local format_mmd = 'mmd'
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
      get_mmd_dir =
        function(Me)
          return get_custom_name(Me, format_mmd)
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
      get_mmd_pathname =
        function(Me, index)
          return
            pathname_to_str(
              {
                get_mmd_dir(Me),
                list_to_str(
                  { represent_index(Me, index), format_mmd },
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
          GetMmdDir = get_mmd_dir,
          GetListingPathname = get_listing_pathname,
          GetTgfPathname = get_tgf_pathname,
          GetDotPathname = get_dot_pathname,
          GetSvgPathname = get_svg_pathname,
          GetMmdPathname = get_mmd_pathname,
        }
    end
    return Methods
  end
package.preload['generate_callgraphs_lua'] =
  function(...)
    require('workshop.base')
    local space
    local newline
    do
      local AsciiChars = request('!.concepts.Ascii.Chars')
      space = AsciiChars.space
      newline = AsciiChars.newline
    end
    local export_listing
    do
      local get_bytecode_listing =
        request('!.programs.get_bytecode_listing')
      local FileStream = request('!.concepts.StreamIo.Output.File')
      export_listing =
        function(sourcecode_pathname, listing_pathname)
          local ListingStream = new(FileStream)
          ListingStream:Open(listing_pathname)
          get_bytecode_listing({ sourcecode_pathname }, ListingStream)
          ListingStream:Close()
        end
    end
    local load_listing
    do
      local parse_itness = request('!.concepts.codec_itness.parse')
      local FileStream = request('!.concepts.StreamIo.Input.File')
      load_listing =
        function(listing_pathname)
          local Result
          local ListingStream = new(FileStream)
          ListingStream:Open(listing_pathname)
          Result = parse_itness(ListingStream)
          ListingStream:Close()
          return Result
        end
    end
    local get_callgraph
    do
      local list_to_str = request('!.concepts.list.to_string')
      local get_next_ones = request('callgraph.get_next_ones')
      local add_to_list = request('!.concepts.list.add_item')
      get_callgraph =
        function(Chunk)
          local Callgraph = {}
          for instruction_index, Instruction in ipairs(Chunk) do
            local CallgraphRec =
              {
                label = list_to_str(Instruction, space),
                NextOnes = get_next_ones(instruction_index, Instruction),
              }
            add_to_list(Callgraph, CallgraphRec)
          end
          return Callgraph
        end
    end
    local export_to_tgf
    local export_to_dot
    local export_to_mmd
    do
      local OutputFileStream =
        request('!.concepts.StreamIo.Output.File')
      do
        local callgraph_to_tgf = request('callgraph.callgraph_to_tgf')
        export_to_tgf =
          function(Callgraph, file_name)
            local OutputStream = new(OutputFileStream)
            OutputStream:Open(file_name)
            callgraph_to_tgf(Callgraph, OutputStream)
            OutputStream:Close()
          end
      end
      do
        local callgraph_to_dot = request('callgraph.callgraph_to_dot')
        export_to_dot =
          function(Callgraph, file_name)
            local OutputStream = new(OutputFileStream)
            OutputStream:Open(file_name)
            callgraph_to_dot(Callgraph, OutputStream)
            OutputStream:Close()
          end
      end
      do
        local callgraph_to_mmd = request('callgraph.callgraph_to_mmd')
        export_to_mmd =
          function(Callgraph, file_name)
            local OutputStream = new(OutputFileStream)
            OutputStream:Open(file_name)
            callgraph_to_mmd(Callgraph, OutputStream)
            OutputStream:Close()
          end
      end
    end
    local dot_to_svg
    do
      local get_cmd_dot_to_svg =
        request('!.mechs.cmdline.get_cmd_dot_to_svg')
      dot_to_svg =
        function(dot_pathname, svg_pathname)
          local Command = get_cmd_dot_to_svg(dot_pathname, svg_pathname)
          local is_ok, Result = Command:Execute()
          if not is_ok then
            error(Result.error)
          end
        end
    end
    local words_to_str = request('!.concepts.words.to_string')
    local ValidWishes = { 'tgf', 'dot', 'svg', 'mmd' }
    local usage_text =
      [[
Creates VM instruction call graphs for Lua code

Usage: <lua_file_name> <output_dir> [<wishes>]

Careful, we will recreate <output_dir>!

<wishes> is a string with space-separated words of what to export
  You have to quote it for shell.
  Possible wishes: ]] ..
      words_to_str(ValidWishes) ..
      [[

  If <wishes> is empty we will process all possible wishes.

-- Martin, 2026-09
]]
    local Config =
      {
        sourcecode_pathname = arg[1],
        output_dir_name = arg[2],
        wishes_str = arg[3],
      }
    local console_write =
      function(str)
        io.stdout:write(str)
      end
    local console_print =
      function(str)
        console_write(str)
        console_write(newline)
      end
    local NamesGiver = request('NamesGiver').create()
    local get_wishes = request('get_wishes')
    do
      local sourcecode_pathname = Config.sourcecode_pathname
      local output_dir_name = Config.output_dir_name
      local wishes_str = Config.wishes_str or ''
      if not (sourcecode_pathname and output_dir_name) then
        console_write(usage_text)
        return
      end
      console_print('( Generating callgraphs')
      NamesGiver:SetOutputDir(output_dir_name)
      local Wishes =
        get_wishes(
          wishes_str,
          ValidWishes,
          { empty_means_all = true, explode_on_unknown = true }
        )
      local action_export_tgf
      local action_export_dot
      local action_export_svg
      local action_export_mmd
      do
        action_export_tgf = Wishes.tgf
        action_export_dot = Wishes.dot or Wishes.svg
        action_export_svg = Wishes.svg
        action_export_mmd = Wishes.mmd
      end
      do
        local recreate_dir = request('!.file_system.directory.recreate')
        recreate_dir(NamesGiver:GetOutputDir())
        if action_export_tgf then
          recreate_dir(NamesGiver:GetTgfDir())
        end
        if action_export_dot then
          recreate_dir(NamesGiver:GetDotDir())
        end
        if action_export_svg then
          recreate_dir(NamesGiver:GetSvgDir())
        end
        if action_export_mmd then
          recreate_dir(NamesGiver:GetMmdDir())
        end
      end
      local Chunks
      do
        local listing_pathname = NamesGiver:GetListingPathname()
        export_listing(sourcecode_pathname, listing_pathname)
        Chunks = load_listing(listing_pathname)
      end
      NamesGiver:SetNumItems(#Chunks)
      for chunk_index, Chunk in ipairs(Chunks) do
        local Callgraph = get_callgraph(Chunk)
        if action_export_tgf then
          export_to_tgf(
            Callgraph, NamesGiver:GetTgfPathname(chunk_index)
          )
        end
        if action_export_dot then
          export_to_dot(
            Callgraph, NamesGiver:GetDotPathname(chunk_index)
          )
          if action_export_svg then
            dot_to_svg(
              NamesGiver:GetDotPathname(chunk_index),
              NamesGiver:GetSvgPathname(chunk_index)
            )
          end
        end
        if action_export_mmd then
          export_to_mmd(
            Callgraph, NamesGiver:GetMmdPathname(chunk_index)
          )
        end
      end
      do
        local remove_dir = request('!.file_system.directory.remove')
        if not Wishes.dot then
          remove_dir(NamesGiver:GetDotDir())
        end
        local remove_file = request('!.file_system.file.remove')
        remove_file(NamesGiver:GetListingPathname())
      end
      console_print(')')
    end
  end
package.preload['workshop.base'] =
  function(...)
    local set_base_prefix
    local split_name
    local get_base_prefix
    local request
    local stack_init
    local stack_add
    local stack_remove
    do
      local str_match = string.match
      local str_find = string.find
      local str_sub = string.sub
      local tbl_pack = table.pack
      local tbl_unpack = table.unpack
      local require = require
      local empty = ''
      local stack_get
      do
        local Names
        local depth
        stack_init =
          function()
            Names = {}
            depth = 1
          end
        stack_get =
          function()
            return Names[depth]
          end
        stack_add =
          function(prefix, name)
            depth = depth + 1
            Names[depth] = { prefix = prefix, name = name }
          end
        stack_remove =
          function()
            depth = depth - 1
          end
      end
      local get_caller_prefix =
        function()
          local NameRec = stack_get()
          if not NameRec then
            return empty
          end
          return NameRec.prefix
        end
      do
        local prefix_name_capture = '^(.+%.)([^%.]+)$'
        split_name =
          function(qualified_name)
            local prefix, name =
              str_match(qualified_name, prefix_name_capture)
            if not prefix then
              prefix = empty
              if str_find(qualified_name, '%.') then
                name = empty
              else
                name = qualified_name
              end
            end
            return prefix, name
          end
      end
      local apply_rel_prefix
      do
        local uplevel_capture = '(.+%.)[^%.]-%.$'
        apply_rel_prefix =
          function(base_prefix, rel_prefix)
            while (str_sub(rel_prefix, 1, 2) == '^.') do
              if (base_prefix == empty) then
                error("Link is outside of caller's prefix.")
              end
              base_prefix =
                str_match(base_prefix, uplevel_capture) or empty
              rel_prefix = str_sub(rel_prefix, 3)
            end
            return base_prefix .. rel_prefix
          end
      end
      do
        local base_prefix
        set_base_prefix =
          function(arg_base_prefix)
            base_prefix = arg_base_prefix
          end
        get_base_prefix =
          function()
            return base_prefix
          end
      end
      local get_require_name =
        function(qualified_name)
          local caller_prefix
          local is_absolute_name =
            (str_sub(qualified_name, 1, 2) == '!.')
          if is_absolute_name then
            qualified_name = str_sub(qualified_name, 3)
            caller_prefix = get_base_prefix()
          else
            caller_prefix = get_caller_prefix()
          end
          local prefix, name = split_name(qualified_name)
          prefix = apply_rel_prefix(caller_prefix, prefix)
          return prefix .. name
        end
      request =
        function(qualified_name)
          local require_name = get_require_name(qualified_name)
          stack_add(split_name(require_name))
          local Results = tbl_pack(require(require_name))
          stack_remove()
          return tbl_unpack(Results)
        end
    end
    do
      local our_require_name = (...)
      set_base_prefix(split_name(our_require_name))
      _G.request = request
      _G.get_base_prefix = get_base_prefix
      stack_init()
      stack_add(empty, our_require_name)
      request('!.system.install_is_functions')()
      request('!.system.install_assert_functions')()
      _G.new = request('!.table.new')
      stack_remove()
    end
  end
package.preload['workshop.system.install_is_functions'] =
  function(...)
    local type_is =
      function(type_name)
        return
          function(val)
            return (type(val) == type_name)
          end
      end
    local number_is
    do
      local math_type = math.type
      number_is =
        function(type_name)
          return
            function(val)
              if not is_number(val) then
                return false
              end
              return (math_type(val) == type_name)
            end
        end
    end
    local TypeNames = request('!.concepts.lua.TypeNames')
    local NumberTypeNames = request('!.concepts.lua.NumberTypeNames')
    return
      function()
        for _, type_name in ipairs(TypeNames) do
          _G['is_' .. type_name] = type_is(type_name)
        end
        for _, number_type_name in ipairs(NumberTypeNames) do
          _G['is_' .. number_type_name] = number_is(number_type_name)
        end
      end
  end
package.preload['workshop.system.install_assert_functions'] =
  function(...)
    local spawn_assert_func
    do
      local str_format = string.format
      spawn_assert_func =
        function(type_name)
          local checker = _G['is_' .. type_name]
          assert(checker)
          return
            function(val)
              if not checker(val) then
                local err_msg =
                  str_format('assert_%s(%s)', type_name, tostring(val))
                error(err_msg)
              end
            end
        end
    end
    local TypeNames = request('!.concepts.lua.TypeNames')
    local NumberTypeNames = request('!.concepts.lua.NumberTypeNames')
    local install_assert_funcs =
      function()
        for _, type_name in ipairs(TypeNames) do
          _G['assert_' .. type_name] = spawn_assert_func(type_name)
        end
        for _, number_type_name in ipairs(NumberTypeNames) do
          _G['assert_' .. number_type_name] =
            spawn_assert_func(number_type_name)
        end
      end
    return install_assert_funcs
  end
package.preload['workshop.programs.get_bytecode_listing'] =
  function(...)
    local file_to_str = request('!.convert.file_to_str')
    local get_bytecode =
      request('!.concepts.lua_bytecode_decompiler.bytecode_from_source')
    local get_listing =
      request(
        '!.concepts.lua_bytecode_decompiler.listing_from_bytecode'
      )
    local itness_to_stream = request('!.concepts.codec_itness.compile')
    return
      function(Args, OutputStream)
        itness_to_stream(
          get_listing(get_bytecode(file_to_str(Args[1]))), OutputStream
        )
      end
  end
package.preload['workshop.lua.regexp.magic_chars'] =
  function(...)
    return '^$()[]%.?*+-'
  end
package.preload['workshop.lua.regexp.magic_char_pattern'] =
  function(...)
    local magic_chars = request('magic_chars')
    local magic_char_patttern =
      '[' .. magic_chars:gsub('.', '%%%0') .. ']'
    return magic_char_patttern
  end
package.preload['workshop.lua.regexp.quote'] =
  function(...)
    local magic_char_pattern = request('magic_char_pattern')
    return
      function(s)
        return s:gsub(magic_char_pattern, '%%%0')
      end
  end
package.preload['workshop.mechs.cmdline.get_cmd_decompile_lua_bytecode'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local ShellCommand = request('!.concepts.ShellCommand')
    local get_cmd_decompile_lua_bytecode =
      function(bytecode_file_name)
        local Command =
          { 'luac', { '-l', '-p', normalize(bytecode_file_name) } }
        return ShellCommand.create(Command)
      end
    return get_cmd_decompile_lua_bytecode
  end
package.preload['workshop.mechs.cmdline.get_cmd_file_exists'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local ShellCommand = request('!.concepts.ShellCommand')
    return
      function(pathname)
        local Command = { 'test', { '-f', normalize(pathname) } }
        return ShellCommand.create(Command)
      end
  end
package.preload['workshop.mechs.cmdline.get_cmd_rmfile'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local ShellCommand = request('!.concepts.ShellCommand')
    return
      function(file_name)
        local Command = { 'rm', { normalize(file_name) } }
        return ShellCommand.create(Command)
      end
  end
package.preload['workshop.mechs.cmdline.get_cmd_dir_exists'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local ShellCommand = request('!.concepts.ShellCommand')
    return
      function(pathname)
        local Command = { 'test', { '-d', normalize(pathname) } }
        return ShellCommand.create(Command)
      end
  end
package.preload['workshop.mechs.cmdline.get_cmd_mkdir'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local ShellCommand = request('!.concepts.ShellCommand')
    return
      function(dir_name)
        local Command = { 'mkdir', { '-p', normalize(dir_name) } }
        return ShellCommand.create(Command)
      end
  end
package.preload['workshop.mechs.cmdline.get_cmd_rmdir'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local ShellCommand = request('!.concepts.ShellCommand')
    return
      function(dir_name)
        local Command = { 'rm', { '-r', '-f', normalize(dir_name) } }
        return ShellCommand.create(Command)
      end
  end
package.preload['workshop.mechs.cmdline.get_cmd_dot_to_svg'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local ShellCommand = request('!.concepts.ShellCommand')
    return
      function(dot_pathname, svg_pathname)
        local Command =
          {
            'dot',
            {
              '-Tsvg',
              normalize(dot_pathname),
              '-o',
              normalize(svg_pathname),
            },
          }
        return ShellCommand.create(Command)
      end
  end
package.preload['workshop.number.is_natural'] =
  function(...)
    return
      function(Number)
        assert_number(Number)
        if not is_integer(Number) then
          return false
        end
        if (Number <= 0) then
          return false
        end
        return true
      end
  end
package.preload['workshop.number.get_num_dec_digits'] =
  function(...)
    local assert_integer = _G.assert_integer
    local abs = math.abs
    local log = math.log
    local floor = math.floor
    local get_num_dec_digits =
      function(n)
        assert_integer(n)
        if (n == 0) then
          return 1
        end
        return floor(log(abs(n), 10)) + 1
      end
    return get_num_dec_digits
  end
package.preload['workshop.table.clone'] =
  function(...)
    return
      function(Node)
        local clone
        do
          local Cloned = {}
          clone =
            function(Node)
              if (type(Node) ~= 'table') then
                return Node
              end
              if Cloned[Node] then
                return Cloned[Node]
              end
              local Result = {}
              Cloned[Node] = Result
              for key, value in pairs(Node) do
                Result[clone(key)] = clone(value)
              end
              setmetatable(Result, getmetatable(Node))
              return Result
            end
        end
        return clone(Node)
      end
  end
package.preload['workshop.table.new'] =
  function(...)
    local clone = request('clone')
    local patch = request('patch')
    return
      function(Base, Overrides)
        assert_table(Base)
        local Result = clone(Base)
        if is_table(Overrides) then
          patch(Result, Overrides)
        end
        return Result
      end
  end
package.preload['workshop.table.patch'] =
  function(...)
    local Rules = { { has_a = true, has_b = true, action = 'replace' } }
    local apply_table = request('apply_table')
    return
      function(Result, Additions)
        apply_table(Result, Additions, Rules)
      end
  end
package.preload['workshop.table.map_values'] =
  function(...)
    return
      function(List)
        assert_table(List)
        local Result = {}
        for _, value in pairs(List) do
          Result[value] = true
        end
        return Result
      end
  end
package.preload['workshop.table.create_instance'] =
  function(...)
    local clone = request('clone')
    local attach_methods = request('attach_methods')
    return
      function(Data, Methods)
        assert_table(Data)
        assert_table(Methods)
        local Result
        Result = clone(Data)
        attach_methods(Result, Methods)
        return Result
      end
  end
package.preload['workshop.table.is_empty'] =
  function(...)
    return
      function(t)
        assert_table(t)
        return is_nil(next(t))
      end
  end
package.preload['workshop.table.get_values'] =
  function(...)
    local add_to_list = request('!.concepts.list.add_item')
    return
      function(List)
        assert_table(List)
        local Values = {}
        for _, value in pairs(List) do
          add_to_list(Values, value)
        end
        return Values
      end
  end
package.preload['workshop.table.subtract'] =
  function(...)
    local Rules = { { has_a = true, has_b = true, action = 'remove' } }
    local apply_table = request('apply_table')
    return
      function(A, B)
        apply_table(A, B, Rules)
      end
  end
package.preload['workshop.table.apply_table'] =
  function(...)
    local keep_str = 'keep'
    local replace_str = 'replace'
    local remove_str = 'remove'
    local get_action =
      function(has_a, has_b, Rules)
        for _, Rule in ipairs(Rules) do
          if (Rule.has_a == has_a) and (Rule.has_b == has_b) then
            return Rule.action
          end
        end
        return keep_str
      end
    local apply_table
    apply_table =
      function(A, B, Rules)
        local Keys = {}
        do
          for a_key in pairs(A) do
            Keys[a_key] = true
          end
          for b_key in pairs(B) do
            Keys[b_key] = true
          end
        end
        for key in pairs(Keys) do
          local a_key = A[key]
          local b_key = B[key]
          if is_table(a_key) and is_table(b_key) then
            apply_table(a_key, b_key, Rules)
          else
            local has_a = not is_nil(a_key)
            local has_b = not is_nil(b_key)
            local action = get_action(has_a, has_b, Rules)
            if (action == keep_str) then
              ;
            elseif (action == replace_str) then
              A[key] = B[key]
            elseif (action == remove_str) then
              A[key] = nil
            end
          end
        end
      end
    local check_rule =
      function(Rule)
        local has_a = is_boolean(Rule.has_a)
        local has_b = is_boolean(Rule.has_b)
        local action = Rule.action
        local is_known_action =
          (action == keep_str) or
          (action == replace_str) or
          (action == remove_str)
        return has_a and has_b and is_known_action
      end
    return
      function(A, B, Rules)
        assert_table(A)
        assert_table(B)
        assert_table(Rules)
        assert(A ~= B)
        for index, Rule in ipairs(Rules) do
          if not check_rule(Rule) then
            error('Unsupported rule.')
          end
        end
        apply_table(A, B, Rules)
      end
  end
package.preload['workshop.table.intersect'] =
  function(...)
    local Rules =
      {
        { has_a = true, has_b = false, action = 'remove' },
        { has_a = false, has_b = true, action = 'remove' },
      }
    local apply_table = request('apply_table')
    return
      function(A, B)
        apply_table(A, B, Rules)
      end
  end
package.preload['workshop.table.attach_methods'] =
  function(...)
    return
      function(Object, Methods)
        assert_table(Object)
        assert_table(Methods)
        local Metatable =
          {
            __index = Methods,
            __newindex =
              function()
                error('Table is locked for additions/removals.')
              end,
          }
        setmetatable(Object, Metatable)
      end
  end
package.preload['workshop.file_system.directory.recreate'] =
  function(...)
    local remove_dir = request('remove')
    local create_dir = request('create')
    return
      function(dir_name)
        return remove_dir(dir_name) and create_dir(dir_name)
      end
  end
package.preload['workshop.file_system.directory.create'] =
  function(...)
    local directory_exists = request('exists')
    local get_mkdir_command = request('!.mechs.cmdline.get_cmd_mkdir')
    return
      function(dir_name)
        assert_string(dir_name)
        if directory_exists(dir_name) then
          return true
        end
        get_mkdir_command(dir_name):Execute()
        if directory_exists(dir_name) then
          return true
        end
        return false
      end
  end
package.preload['workshop.file_system.directory.exists'] =
  function(...)
    local get_cmd_dir_exists =
      request('!.mechs.cmdline.get_cmd_dir_exists')
    return
      function(dir_name)
        return (get_cmd_dir_exists(dir_name):Execute())
      end
  end
package.preload['workshop.file_system.directory.remove'] =
  function(...)
    local directory_exists = request('exists')
    local get_rmdir_command = request('!.mechs.cmdline.get_cmd_rmdir')
    return
      function(dir_name)
        assert_string(dir_name)
        if not directory_exists(dir_name) then
          return true
        end
        get_rmdir_command(dir_name):Execute()
        if not directory_exists(dir_name) then
          return true
        end
        return false
      end
  end
package.preload['workshop.file_system.file.open'] =
  function(...)
    local normalize_name = request('!.concepts.path_name.normalize')
    local default_mode = 'rb'
    local io_open = io.open
    return
      function(pathname, mode)
        assert_string(pathname)
        assert(is_nil(mode) or is_string(mode))
        pathname = normalize_name(pathname)
        mode = mode or default_mode
        local file, err_msg = io.open(pathname, mode)
        if not file then
          error(err_msg, 2)
        end
        return file
      end
  end
package.preload['workshop.file_system.file.open_for_writing'] =
  function(...)
    local open_file = request('open')
    return
      function(pathname)
        return open_file(pathname, 'w+b')
      end
  end
package.preload['workshop.file_system.file.close'] =
  function(...)
    local io_type = io.type
    return
      function(File)
        local file_type = io_type(File)
        if not is_string(file_type) then
          return
        end
        if (file_type == 'closed file') then
          return
        end
        File:close()
      end
  end
package.preload['workshop.file_system.file.create'] =
  function(...)
    local open_file = request('open')
    local close_file = request('close')
    return
      function(pathname, contents)
        assert_string(pathname)
        assert_string(contents)
        local File = open_file(pathname, 'wb')
        File:write(contents)
        close_file(File)
      end
  end
package.preload['workshop.file_system.file.to_string'] =
  function(...)
    local open_file = request('open')
    local close_file = request('close')
    return
      function(pathname)
        local File = open_file(pathname, 'rb')
        local result = File:read('a')
        close_file(File)
        return result
      end
  end
package.preload['workshop.file_system.file.exists'] =
  function(...)
    local get_cmd_file_exists =
      request('!.mechs.cmdline.get_cmd_file_exists')
    return
      function(file_name)
        return (get_cmd_file_exists(file_name):Execute())
      end
  end
package.preload['workshop.file_system.file.open_for_reading'] =
  function(...)
    local open_file = request('open')
    return
      function(pathname)
        return open_file(pathname, 'rb')
      end
  end
package.preload['workshop.file_system.file.remove'] =
  function(...)
    local file_exists = request('exists')
    local get_rmfile_command = request('!.mechs.cmdline.get_cmd_rmfile')
    return
      function(pathname)
        assert_string(pathname)
        if not file_exists(pathname) then
          return true
        end
        get_rmfile_command(pathname):Execute()
        if not file_exists(pathname) then
          return true
        end
        return false
      end
  end
package.preload['workshop.string.trim'] =
  function(...)
    local trim_head = request('trim_head')
    local trim_tail = request('trim_tail')
    return
      function(s)
        return trim_head(trim_tail(s))
      end
  end
package.preload['workshop.string.starts_with'] =
  function(...)
    local str_sub = string.sub
    return
      function(base_str, prefix_str)
        return (str_sub(base_str, 1, #prefix_str) == prefix_str)
      end
  end
package.preload['workshop.string.trim_tail'] =
  function(...)
    local trim_tail =
      function(str)
        assert_string(str)
        local read_pos = string.len(str)
        while (string.sub(str, read_pos, read_pos) == ' ') do
          read_pos = read_pos - 1
        end
        return string.sub(str, 1, read_pos)
      end
    return trim_tail
  end
package.preload['workshop.string.ends_with'] =
  function(...)
    local str_sub = string.sub
    return
      function(base_str, postfix_str)
        return (str_sub(base_str, -#postfix_str, -1) == postfix_str)
      end
  end
package.preload['workshop.string.trim_head'] =
  function(...)
    local trim_head =
      function(str)
        assert_string(str)
        local read_pos = 1
        while (string.sub(str, read_pos, read_pos) == ' ') do
          read_pos = read_pos + 1
        end
        return string.sub(str, read_pos, string.len(str))
      end
    return trim_head
  end
package.preload['workshop.string.split'] =
  function(...)
    local ends_with = request('!.string.ends_with')
    local quote_regexp = request('!.lua.regexp.quote')
    local str_find = string.find
    local add_to_list = request('!.concepts.list.add_item')
    return
      function(str, delimiter)
        assert_string(str)
        assert_string(delimiter)
        if (delimiter == '') then
          return { str }
        end
        if not ends_with(str, delimiter) then
          str = str .. delimiter
        end
        local Result = {}
        local item_capture = '(.-)' .. quote_regexp(delimiter) .. '()'
        local start_pos
        local end_pos
        local item_str
        start_pos = 1
        while true do
          start_pos, end_pos, item_str =
            str_find(str, item_capture, start_pos)
          if not start_pos then
            break
          end
          add_to_list(Result, item_str)
          start_pos = end_pos + 1
        end
        return Result
      end
  end
package.preload['workshop.convert.file_to_str'] =
  function(...)
    return request('!.file_system.file.to_string')
  end
package.preload['workshop.convert.file_from_str'] =
  function(...)
    return request('!.file_system.file.create')
  end
package.preload['workshop.concepts.ShellCommand'] =
  function(...)
    local ToString
    do
      local quote = request('!.concepts.shell.quote')
      local add_to_list = request('!.concepts.list.add_item')
      local glue_words = request('!.concepts.words.to_string')
      ToString =
        function(Me)
          local command = Me[1]
          local Args = Me[2]
          local Words = {}
          add_to_list(Words, quote(command))
          for _, arg in ipairs(Args) do
            add_to_list(Words, quote(arg))
          end
          return glue_words(Words)
        end
    end
    local Execute
    do
      local execute_shell_command = request('!.concepts.shell.execute')
      Execute =
        function(Me)
          return execute_shell_command(Me:ToString())
        end
    end
    local Interface
    do
      local create
      do
        local create_instance = request('!.table.create_instance')
        create =
          function(Core)
            do
              assert_table(Core)
              assert(#Core == 2)
              local command = Core[1]
              local Args = Core[2]
              assert_string(command)
              assert_table(Args)
              for _, arg in ipairs(Args) do
                assert_string(arg)
              end
            end
            return create_instance(Core, Interface)
          end
      end
      Interface =
        { create = create, ToString = ToString, Execute = Execute }
    end
    return Interface
  end
package.preload['workshop.concepts.Indent'] =
  function(...)
    local get_indent_chunk =
      function(Me)
        return Me[1]
      end
    local set_indent_chunk =
      function(Me, str)
        Me[1] = str
      end
    local get_indent_level =
      function(Me)
        return Me[2]:GetValue()
      end
    local set_indent_level =
      function(Me, level)
        Me[2]:SetValue(level)
      end
    local to_string
    do
      local str_rep = string.rep
      to_string =
        function(Me)
          return str_rep(Me[1], Me[2]:GetValue())
        end
    end
    local inc =
      function(Me)
        set_indent_level(Me, get_indent_level(Me) + 1)
      end
    local dec =
      function(Me)
        set_indent_level(Me, get_indent_level(Me) - 1)
      end
    local Interface
    local create
    do
      local RangePointClass = request('!.concepts.RangePoint')
      local default_indent_chunk = '  '
      local default_min_indent = 0
      local default_max_indent = 60
      local attach_methods = request('!.table.attach_methods')
      create =
        function(OptArg)
          local min_indent = default_min_indent
          local max_indent = default_max_indent
          if OptArg then
            min_indent = OptArg.min or min_indent
            max_indent = OptArg.max or max_indent
          end
          local RangePoint = RangePointClass.create()
          RangePoint:SetMinValue(min_indent)
          RangePoint:SetMaxValue(max_indent)
          RangePoint:SetValue(min_indent)
          local Core = { default_indent_chunk, RangePoint }
          attach_methods(Core, Interface)
          return Core
        end
    end
    Interface =
      {
        create = create,
        GetIndentChunk = get_indent_chunk,
        SetIndentChunk = set_indent_chunk,
        GetIndentLevel = get_indent_level,
        SetIndentLevel = set_indent_level,
        ToString = to_string,
        Inc = inc,
        Dec = dec,
      }
    return Interface
  end
package.preload['workshop.concepts.RangePoint'] =
  function(...)
    local get_min_value =
      function(Me)
        return Me[2]
      end
    local set_min_value =
      function(Me, val)
        Me[2] = val
      end
    local get_max_value =
      function(Me)
        return Me[3]
      end
    local set_max_value =
      function(Me, val)
        Me[3] = val
      end
    local get_value
    local set_value
    do
      local min = math.min
      local max = math.max
      get_value =
        function(Me)
          return min(max(Me[1], Me[2]), Me[3])
        end
      set_value =
        function(Me, value)
          Me[1] = min(max(value, Me[2]), Me[3])
        end
    end
    local Interface
    local create
    do
      local attach_methods = request('!.table.attach_methods')
      create =
        function()
          local Core = { 0, 0, 1 }
          attach_methods(Core, Interface)
          return Core
        end
    end
    Interface =
      {
        create = create,
        GetMinValue = get_min_value,
        SetMinValue = set_min_value,
        GetMaxValue = get_max_value,
        SetMaxValue = set_max_value,
        GetValue = get_value,
        SetValue = set_value,
      }
    return Interface
  end
package.preload['workshop.concepts.PaddedIndex'] =
  function(...)
    local to_string
    do
      local str_format = string.format
      to_string =
        function(Me, index)
          return str_format(Me[1], index)
        end
    end
    local Interface
    local create
    do
      local is_natural = request('!.number.is_natural')
      local get_num_dec_digits = request('!.number.get_num_dec_digits')
      local int_to_str = tostring
      local create_instance = request('!.table.create_instance')
      create =
        function(max_index)
          assert(is_natural(max_index))
          local zeroes_padding_format =
            '%0' .. int_to_str(get_num_dec_digits(max_index)) .. 'd'
          return create_instance({ zeroes_padding_format }, Interface)
        end
    end
    Interface = { create = create, ToString = to_string }
    return Interface
  end
package.preload['workshop.concepts.lua.NumberTypeNames'] =
  function(...)
    return { 'integer', 'float' }
  end
package.preload['workshop.concepts.lua.TypeNames'] =
  function(...)
    return
      {
        'nil',
        'boolean',
        'number',
        'string',
        'function',
        'thread',
        'userdata',
        'table',
      }
  end
package.preload['workshop.concepts.shell.split_shebang'] =
  function(...)
    local shebang_prefix = '#!'
    local newline = request('!.concepts.Ascii.Chars').newline
    local starts_with = request('!.string.starts_with')
    local str_find = string.find
    local str_sub = string.sub
    return
      function(str)
        assert_string(str)
        if not starts_with(str, shebang_prefix) then
          return nil, str
        end
        local newline_pos = str_find(str, newline)
        if not newline_pos then
          return str, ''
        end
        local shebang_str = str_sub(str, 1, newline_pos - 1)
        local rest_str = str_sub(str, newline_pos + 1)
        return shebang_str, rest_str
      end
  end
package.preload['workshop.concepts.shell.quote'] =
  function(...)
    local empty = ''
    local single_quote
    local backslash
    do
      local Ascii = request('!.concepts.Ascii.Chars')
      single_quote = Ascii.single_quote
      backslash = Ascii.backslash
    end
    local list_to_str = request('!.concepts.list.to_string')
    local str_find = string.find
    local needs_quoting
    do
      local special_chars_regexp
      local starts_with_comment_regexp
      do
        local quote_regexp = request('!.lua.regexp.quote')
        do
          local SpecialChars = request('quote.SpecialChars')
          local special_chars_str = list_to_str(SpecialChars)
          special_chars_regexp =
            '[' .. quote_regexp(special_chars_str) .. ']'
        end
        do
          local SpaceChars = request('quote.SpaceChars')
          local space_chars_str = list_to_str(SpaceChars)
          local space_chars_regexp =
            '[' .. quote_regexp(space_chars_str) .. ']'
          local comment_char = '#'
          starts_with_comment_regexp =
            '^' .. space_chars_regexp .. '+' .. comment_char
        end
      end
      needs_quoting =
        function(str)
          return
            (str == empty) or
            not is_nil(str_find(str, special_chars_regexp)) or
            not is_nil(str_find(str, starts_with_comment_regexp))
        end
    end
    local split_string = request('!.string.split')
    local add_to_list = request('!.concepts.list.add_item')
    local quote
    quote =
      function(str)
        assert_string(str)
        if not needs_quoting(str) then
          return str
        end
        if not str_find(str, single_quote) then
          return single_quote .. str .. single_quote
        end
        str = str .. single_quote
        local RawItems = split_string(str, single_quote)
        local Items = {}
        for _, item in ipairs(RawItems) do
          local quoted_item
          if (item == empty) then
            quoted_item = empty
          else
            quoted_item = quote(item)
          end
          add_to_list(Items, quoted_item)
        end
        return list_to_str(Items, backslash .. single_quote)
      end
    return quote
  end
package.preload['workshop.concepts.shell.execute'] =
  function(...)
    local get_is_aborted =
      function(result_type_code)
        if (result_type_code == 'signal') then
          return true
        elseif (result_type_code == 'exit') then
          return false
        else
          error('Unknown termination status.')
        end
      end
    local os_tmpname = os.tmpname
    local os_execute = os.execute
    local file_to_str = request('!.convert.file_to_str')
    local os_remove = os.remove
    return
      function(command)
        local output_filename = os_tmpname()
        local error_filename = os_tmpname()
        local shell_command =
          command ..
          ' ' ..
          '1>' ..
          output_filename ..
          ' ' ..
          '2>' ..
          error_filename
        local _, result_type_code, result_code =
          os_execute(shell_command)
        local Result =
          {
            result_code = result_code,
            is_aborted = get_is_aborted(result_type_code),
            output = file_to_str(output_filename),
            error = file_to_str(error_filename),
          }
        os_remove(output_filename)
        os_remove(error_filename)
        return (Result.result_code == 0), Result
      end
  end
package.preload['workshop.concepts.shell.quote.SpecialChars'] =
  function(...)
    local SpecialChars
    do
      local Ascii = request('!.concepts.Ascii.Chars')
      local SpaceChars = request('SpaceChars')
      local add_list = request('!.concepts.list.add_list')
      SpecialChars =
        {
          Ascii.single_quote,
          Ascii.double_quote,
          Ascii.bang,
          Ascii.dollar_sign,
          Ascii.ampersand,
          Ascii.asterisk,
          Ascii.semicolon,
          Ascii.backslash,
          Ascii.caret,
          Ascii.backtick,
          Ascii.pipe,
          Ascii.less_than,
          Ascii.greater_than,
          Ascii.opening_paren,
          Ascii.closing_paren,
          Ascii.opening_bracket,
          Ascii.closing_bracket,
          Ascii.opening_brace,
          Ascii.closing_brace,
        }
      add_list(SpecialChars, SpaceChars)
    end
    return SpecialChars
  end
package.preload['workshop.concepts.shell.quote.SpaceChars'] =
  function(...)
    local SpaceChars
    do
      local Ascii = request('!.concepts.Ascii.Chars')
      SpaceChars = { Ascii.tab, Ascii.space, Ascii.newline }
    end
    return SpaceChars
  end
package.preload['workshop.concepts.list.to_string'] =
  function(...)
    local tbl_concat = table.concat
    return
      function(List, separator_str)
        assert_table(List)
        separator_str = separator_str or ''
        assert_string(separator_str)
        return tbl_concat(List, separator_str)
      end
  end
package.preload['workshop.concepts.list.add_item'] =
  function(...)
    local tbl_insert = table.insert
    return
      function(OurList, item)
        tbl_insert(OurList, item)
      end
  end
package.preload['workshop.concepts.list.add_list'] =
  function(...)
    local tbl_move = table.move
    return
      function(OurList, AnotherList)
        assert(OurList ~= AnotherList)
        tbl_move(AnotherList, 1, #AnotherList, #OurList + 1, OurList)
      end
  end
package.preload['workshop.concepts.words.from_string'] =
  function(...)
    local str_gmatch = string.gmatch
    local add_to_list = request('!.concepts.list.add_item')
    return
      function(str)
        local Words = {}
        for word in str_gmatch(str, '%S+') do
          add_to_list(Words, word)
        end
        return Words
      end
  end
package.preload['workshop.concepts.words.to_string'] =
  function(...)
    local list_to_string = request('!.concepts.list.to_string')
    return
      function(Words)
        return list_to_string(Words, ' ')
      end
  end
package.preload['workshop.concepts.codec_itness.parse'] =
  function(...)
    local Syntax = request('common.Syntax')
    local read_token
    do
      local quote_open_char = Syntax.quote_open_char
      local quote_close_char = Syntax.quote_close_char
      local space_char = Syntax.delimiters_space_char
      local newline_char = Syntax.delimiters_newline_char
      read_token =
        function(Input)
          local token = ''
          local in_quotes = false
          while true do
            local char = Input:Read(1)
            if (char == '') then
              return token
            end
            if in_quotes then
              if (char == quote_close_char) then
                in_quotes = false
              else
                token = token .. char
              end
            else
              if (char == space_char) or (char == newline_char) then
                if (token ~= '') then
                  return token
                end
              elseif (char == quote_open_char) then
                in_quotes = true
              else
                token = token .. char
              end
            end
          end
        end
    end
    local parse
    do
      local group_open_char = Syntax.group_open_char
      local group_close_char = Syntax.group_close_char
      local add_to_list = request('!.concepts.list.add_item')
      parse =
        function(Input)
          while true do
            local token = read_token(Input)
            if (token == '') then
              return
            end
            if (token == group_open_char) then
              local Result = {}
              while true do
                local Node = parse(Input)
                if not Node then
                  break
                end
                add_to_list(Result, Node)
              end
              return Result
            elseif (token == group_close_char) then
              return
            else
              return token
            end
          end
        end
    end
    return parse
  end
package.preload['workshop.concepts.codec_itness.compile'] =
  function(...)
    local DataWriter = request('compile.DataWriter.Interface')
    local DelimitersWriter =
      request('compile.DelimitersWriter.Interface')
    local Syntax = request('common.Syntax')
    return
      function(Node, Output)
        local DataWriter = new(DataWriter)
        local DelimitersWriter = new(DelimitersWriter)
        local compile
        compile =
          function(Node)
            if is_string(Node) then
              DelimitersWriter:HandleEvent('write_string')
              DataWriter:WriteLeaf(Node)
            elseif is_table(Node) then
              DelimitersWriter:HandleEvent('start_list')
              DataWriter:StartList()
              for _, Node in ipairs(Node) do
                compile(Node)
              end
              DelimitersWriter:HandleEvent('end_list')
              DataWriter:EndList()
            end
          end
        DataWriter.Output = Output
        DataWriter.Syntax = Syntax
        DataWriter:Init()
        DelimitersWriter.Output = Output
        DelimitersWriter.space_char = Syntax.delimiters_space_char
        DelimitersWriter.newline_char = Syntax.delimiters_newline_char
        DelimitersWriter:Init()
        compile(Node)
        DelimitersWriter:HandleEvent('nothing')
      end
  end
package.preload['workshop.concepts.codec_itness.common.Syntax'] =
  function(...)
    local Syntax =
      {
        delimiters_space_char = ' ',
        delimiters_newline_char = '\n',
        quote_open_char = '[',
        quote_close_char = ']',
        group_open_char = '(',
        group_close_char = ')',
      }
    return Syntax
  end
package.preload[
  'workshop.concepts.codec_itness.compile.DataWriter.WriteLeaf'
] =
  function(...)
    local WriteLeaf =
      function(Me, str)
        local quote_open_char = Me.Syntax.quote_open_char
        local quote_close_char = Me.Syntax.quote_close_char
        local IsSyntaxChar_Map = Me.IsSyntaxChar_Map
        local syntax_chars_regexp = Me.syntax_chars_regexp
        local in_quotes = false
        local encode_char =
          function(char)
            local Result = char
            if
              not in_quotes and
              (IsSyntaxChar_Map[char] and (char ~= quote_close_char))
            then
              Result = quote_open_char .. char
              in_quotes = true
            end
            if in_quotes and (char == quote_close_char) then
              Result = quote_close_char .. char
              in_quotes = false
            end
            return Result
          end
        local encoded_str =
          string.gsub(str, syntax_chars_regexp, encode_char)
        if in_quotes then
          encoded_str = encoded_str .. quote_close_char
          in_quotes = false
        end
        if (str == '') then
          encoded_str = quote_open_char .. quote_close_char
        end
        Me.Output:Write(encoded_str)
      end
    return WriteLeaf
  end
package.preload[
  'workshop.concepts.codec_itness.compile.DataWriter.Interface'
] =
  function(...)
    local get_values = request('!.table.get_values')
    local map_values = request('!.table.map_values')
    local list_to_string = request('!.concepts.list.to_string')
    local lua_regexp_quote = request('!.lua.regexp.quote')
    local Interface =
      {
        Output = {},
        Syntax = {},
        Init =
          function(Me)
            local SyntaxList = get_values(Me.Syntax)
            Me.IsSyntaxChar_Map = map_values(SyntaxList)
            Me.syntax_chars_regexp =
              '[' .. lua_regexp_quote(list_to_string(SyntaxList)) .. ']'
          end,
        StartList =
          function(Me)
            Me.Output:Write(Me.Syntax.group_open_char)
          end,
        EndList =
          function(Me)
            Me.Output:Write(Me.Syntax.group_close_char)
          end,
        WriteLeaf = request('WriteLeaf'),
        IsSyntaxChar_Map = {},
        syntax_chars_regexp = '',
      }
    return Interface
  end
package.preload[
  'workshop.concepts.codec_itness.compile.DelimitersWriter.Interface'
] =
  function(...)
    local IndentClass = request('!.concepts.Indent')
    local Interface =
      {
        Output = {},
        space_char = '',
        newline_char = '',
        Init =
          function(Me)
            Me.Indent = IndentClass.create()
            local space_char = Me.space_char
            local spaces_per_indent = 2
            local indent_chunk =
              string.rep(space_char, spaces_per_indent)
            Me.Indent:SetIndentChunk(indent_chunk)
            Me.prev_event = 'nothing'
            Me.is_on_empty_line = true
          end,
        HandleEvent = request('HandleEvent'),
        Indent = Indent,
        prev_event = '',
        is_on_empty_line = false,
      }
    return Interface
  end
package.preload[
  'workshop.concepts.codec_itness.compile.DelimitersWriter.HandleEvent'
] =
  function(...)
    local Emit =
      function(Me, str)
        if (str == '') then
          return
        end
        Me.Output:Write(str)
        Me.is_on_empty_line = false
      end
    local EmitNewline =
      function(Me)
        if Me.is_on_empty_line then
          return
        end
        Emit(Me, Me.newline_char)
        Me.is_on_empty_line = true
      end
    local EmitIndent =
      function(Me)
        EmitNewline(Me)
        Emit(Me, Me.Indent:ToString())
      end
    local F_Empty =
      function(Me)
      end
    local F_Indent =
      function(Me)
        EmitIndent(Me)
      end
    local F_Space =
      function(Me)
        Emit(Me, Me.space_char)
      end
    local EventsToFunc =
      {
        ['nothing'] =
          {
            ['nothing'] = F_Empty,
            ['write_string'] = F_Empty,
            ['start_list'] = F_Empty,
            ['end_list'] = F_Empty,
          },
        ['write_string'] =
          {
            ['nothing'] = F_Empty,
            ['write_string'] = F_Space,
            ['start_list'] = F_Indent,
            ['end_list'] = F_Space,
          },
        ['start_list'] =
          {
            ['nothing'] = F_Empty,
            ['write_string'] = F_Space,
            ['start_list'] = F_Indent,
            ['end_list'] = F_Empty,
          },
        ['end_list'] =
          {
            ['nothing'] = F_Indent,
            ['write_string'] = F_Indent,
            ['start_list'] = F_Indent,
            ['end_list'] = F_Indent,
          },
      }
    local OnEvent =
      function(Me, cur_event)
        if (Me.prev_event ~= 'nothing') then
          Me.is_on_empty_line = false
        end
        if (cur_event == 'end_list') then
          Me.Indent:Dec()
        end
        local PaddingFunc = EventsToFunc[Me.prev_event][cur_event]
        PaddingFunc(Me)
        if (cur_event == 'start_list') then
          Me.Indent:Inc()
        end
        Me.prev_event = cur_event
      end
    return OnEvent
  end
package.preload['workshop.concepts.Ascii.Chars'] =
  function(...)
    local Chars
    do
      local Codes = request('Codes')
      local str_char = string.char
      Chars = {}
      for name, code in pairs(Codes) do
        Chars[name] = str_char(code)
      end
    end
    return Chars
  end
package.preload['workshop.concepts.Ascii.is_alnum'] =
  function(...)
    return
      function(code)
        return
          ((code >= 65) and (code <= 90)) or
          ((code >= 97) and (code <= 122)) or
          ((code >= 48) and (code <= 57))
      end
  end
package.preload['workshop.concepts.Ascii.Codes'] =
  function(...)
    return
      {
        bell = 7,
        backspace = 8,
        tab = 9,
        newline = 10,
        vertical_tab = 11,
        form_feed = 12,
        carriage_return = 13,
        space = 32,
        delete = 127,
        plus = 43,
        minus = 45,
        asterisk = 42,
        slash = 47,
        less_than = 60,
        equals = 61,
        greater_than = 62,
        dot = 46,
        comma = 44,
        colon = 58,
        semicolon = 59,
        single_quote = 39,
        double_quote = 34,
        backtick = 96,
        backslash = 92,
        number_sign = 35,
        question_mark = 63,
        bang = 33,
        percent = 37,
        ampersand = 38,
        dollar_sign = 36,
        at_sign = 64,
        caret = 94,
        underscore = 95,
        pipe = 124,
        tilde = 126,
        opening_paren = 40,
        closing_paren = 41,
        opening_bracket = 91,
        closing_bracket = 93,
        opening_brace = 123,
        closing_brace = 125,
      }
  end
package.preload[
  'workshop.concepts.lua_bytecode_decompiler.listing_from_bytecode'
] =
  function(...)
    local get_listing = request('listing_from_bytecode.get_listing')
    local StringStream = request('!.concepts.StreamIo.Input.String')
    local LinesStream = request('!.concepts.StreamIo.Input.Lines')
    local parse_listing = request('listing_from_bytecode.parse_listing')
    local listing_from_bytecode =
      function(bytecode_str)
        assert_string(bytecode_str)
        local listing_str = get_listing(bytecode_str)
        local StringStream = new(StringStream)
        StringStream:Init(listing_str)
        local LinesStream = new(LinesStream)
        LinesStream:Init(StringStream)
        return parse_listing(LinesStream)
      end
    return listing_from_bytecode
  end
package.preload[
  'workshop.concepts.lua_bytecode_decompiler.bytecode_from_function'
] =
  function(...)
    local get_func_code = string.dump
    local strip = true
    local bytecode_from_function =
      function(lua_func)
        assert_function(lua_func)
        return get_func_code(lua_func, strip)
      end
    return bytecode_from_function
  end
package.preload[
  'workshop.concepts.lua_bytecode_decompiler.bytecode_from_source'
] =
  function(...)
    local split_shebang = request('!.concepts.shell.split_shebang')
    local bytecode_from_function = request('bytecode_from_function')
    local compile_source = load
    local bytecode_from_source =
      function(source_code_str)
        assert_string(source_code_str)
        local shebang_str, source_code_str =
          split_shebang(source_code_str)
        local lua_func = compile_source(source_code_str)
        if not lua_func then
          return
        end
        return bytecode_from_function(lua_func)
      end
    return bytecode_from_source
  end
package.preload[
  'workshop.concepts.lua_bytecode_decompiler.listing_from_bytecode.parse_listing'
] =
  function(...)
    local space
    local tab
    local semicolon
    do
      local AsciiChars = request('!.concepts.Ascii.Chars')
      space = AsciiChars.space
      tab = AsciiChars.tab
      semicolon = AsciiChars.semicolon
    end
    local cleanup_spaces
    do
      local str_gsub = string.gsub
      local str_trim = request('!.string.trim')
      cleanup_spaces =
        function(str)
          str = str_gsub(str, tab, space)
          str = str_gsub(str, space .. space .. '+', space)
          str = str_trim(str)
          return str
        end
    end
    local str_split
    do
      local base_str_split = request('!.string.split')
      str_split =
        function(str)
          return base_str_split(str, space)
        end
    end
    local parse_line =
      function(str)
        return str_split(cleanup_spaces(str))
      end
    local add_to_list = request('!.concepts.list.add_item')
    local parse_function =
      function(InputLinesStream)
        local remove_first_item =
          function(List)
            local remove_item = table.remove
            remove_item(List, 1)
          end
        InputLinesStream:Read()
        InputLinesStream:Read()
        local is_ok, opcode_line = InputLinesStream:Read()
        if not is_ok then
          return false
        end
        local Instructions = {}
        do
          local comment_char = semicolon
          local str_find = string.find
          local str_sub = string.sub
          while true do
            if not is_ok then
              break
            end
            if (opcode_line == '') then
              break
            end
            local Instruction
            do
              local comment_pos = str_find(opcode_line, comment_char)
              if comment_pos then
                opcode_line = str_sub(opcode_line, 1, comment_pos - 1)
              end
              Instruction = parse_line(opcode_line)
              remove_first_item(Instruction)
              remove_first_item(Instruction)
            end
            add_to_list(Instructions, Instruction)
            is_ok, opcode_line = InputLinesStream:Read()
          end
        end
        return true, Instructions
      end
    local parse_listing =
      function(InputLinesStream)
        local Functions = {}
        InputLinesStream:Read()
        while true do
          local is_ok, Function = parse_function(InputLinesStream)
          if not is_ok then
            break
          end
          add_to_list(Functions, Function)
        end
        return Functions
      end
    return parse_listing
  end
package.preload[
  'workshop.concepts.lua_bytecode_decompiler.listing_from_bytecode.get_listing'
] =
  function(...)
    local os_tmpname = os.tmpname
    local file_from_str = request('!.convert.file_from_str')
    local get_cmd_decompile =
      request('!.mechs.cmdline.get_cmd_decompile_lua_bytecode')
    local remove_file = request('!.file_system.file.remove')
    return
      function(bytecode_str)
        local output_str
        local bytecode_file_name = os_tmpname()
        file_from_str(bytecode_file_name, bytecode_str)
        local Command = get_cmd_decompile(bytecode_file_name)
        local is_ok, Results = Command:Execute()
        if not is_ok then
          output_str = ''
        else
          output_str = Results.output
        end
        remove_file(bytecode_file_name)
        return output_str
      end
  end
package.preload['workshop.concepts.StreamIo.Input.File'] =
  function(...)
    local open_file_for_reading =
      request('!.file_system.file.open_for_reading')
    local close_file = request('!.file_system.file.close')
    local is_natural = request('!.number.is_natural')
    local Interface =
      {
        Open =
          function(Me, pathname)
            Me.File = open_file_for_reading(pathname)
          end,
        Close =
          function(Me)
            close_file(Me.File)
          end,
        Read =
          function(Me, num_bytes)
            assert(is_natural(num_bytes))
            local data_str = Me.File:read(num_bytes)
            if is_nil(data_str) then
              data_str = ''
            end
            return data_str
          end,
        File = nil,
      }
    setmetatable(
      Interface,
      {
        __gc =
          function(Me)
            Me:Close()
          end,
      }
    )
    return Interface
  end
package.preload['workshop.concepts.StreamIo.Input.String'] =
  function(...)
    local is_natural = request('!.number.is_natural')
    local Interface =
      {
        Init =
          function(Me, arg_data_str)
            assert_string(arg_data_str)
            Me.data_str = arg_data_str
            Me.data_len = string.len(Me.data_str)
            Me.read_pos = 1
          end,
        Read =
          function(Me, num_bytes)
            assert(is_natural(num_bytes))
            local start_pos = Me.read_pos
            local end_pos =
              math.min(start_pos + num_bytes - 1, Me.data_len)
            Me.read_pos = end_pos + 1
            return string.sub(Me.data_str, start_pos, end_pos)
          end,
        data_str = '',
        data_len = 0,
        read_pos = 1,
      }
    return Interface
  end
package.preload['workshop.concepts.StreamIo.Input.Lines'] =
  function(...)
    local newline
    do
      local AsciiChars = request('!.concepts.Ascii.Chars')
      newline = AsciiChars.newline
    end
    local Init =
      function(Me, BaseStream)
        Me.BaseStream = BaseStream
      end
    local Read =
      function(Me)
        local BaseStream = Me.BaseStream
        local char = BaseStream:Read(1)
        if (char == '') then
          return false
        end
        local line = ''
        while true do
          if (char == '') then
            break
          end
          if (char == newline) then
            break
          end
          line = line .. char
          char = BaseStream:Read(1)
        end
        return true, line
      end
    local Interface = { Init = Init, Read = Read, BaseStream = {} }
    return Interface
  end
package.preload['workshop.concepts.StreamIo.Output.File'] =
  function(...)
    local open_file_for_writing =
      request('!.file_system.file.open_for_writing')
    local close_file = request('!.file_system.file.close')
    local Interface =
      {
        Open =
          function(Me, pathname)
            Me.File = open_file_for_writing(pathname)
          end,
        Close =
          function(Me)
            close_file(Me.File)
          end,
        Write =
          function(Me, data_str)
            assert_string(data_str)
            Me.File:write(data_str)
          end,
        File = 0,
      }
    setmetatable(
      Interface,
      {
        __gc =
          function(Me)
            Me:Close()
          end,
      }
    )
    return Interface
  end
package.preload['workshop.concepts.path_name.pathname_to_str'] =
  function(...)
    local sep = request('Syntels').separator
    local clean_pathname
    do
      local clean_name
      do
        local ends_with = request('!.string.ends_with')
        local str_sub = string.sub
        clean_name =
          function(name)
            local sep_len = #sep
            while ends_with(name, sep) do
              name = str_sub(name, 1, -(sep_len + 1))
            end
            return name
          end
      end
      local add_to_list = request('!.concepts.list.add_item')
      clean_pathname =
        function(Pathname)
          local Result = {}
          for _, name in ipairs(Pathname) do
            add_to_list(Result, clean_name(name))
          end
          return Result
        end
    end
    local list_to_str = request('!.concepts.list.to_string')
    return
      function(Pathname)
        return list_to_str(clean_pathname(Pathname), sep)
      end
  end
package.preload['workshop.concepts.path_name.pathname_from_str'] =
  function(...)
    local split_string = request('!.string.split')
    local check_is_absolute = request('is_absolute')
    local check_is_directory = request('is_directory')
    local add_to_list = request('!.concepts.list.add_item')
    local add_list = request('!.concepts.list.add_list')
    local empty = ''
    local self_dir
    local sep
    do
      local Syntels = request('Syntels')
      self_dir = Syntels.self_dir
      sep = Syntels.separator
    end
    return
      function(path_name)
        assert_string(path_name)
        if (path_name == empty) then
          error('Empty pathname.')
        end
        local is_absolute
        local is_directory
        local Names = {}
        do
          local Segments = split_string(path_name .. sep, sep)
          is_absolute = check_is_absolute(Segments)
          is_directory = check_is_directory(Segments)
          for _, segment in ipairs(Segments) do
            if (segment ~= empty) and (segment ~= self_dir) then
              add_to_list(Names, segment)
            end
          end
        end
        if (#Names == 0) and not is_absolute then
          add_to_list(Names, self_dir)
        end
        do
          local Result = {}
          if is_absolute then
            add_to_list(Result, empty)
          end
          add_list(Result, Names)
          if is_directory then
            add_to_list(Result, empty)
          end
          return Result
        end
      end
  end
package.preload['workshop.concepts.path_name.normalize'] =
  function(...)
    local pathname_from_str = request('pathname_from_str')
    local pathname_to_str = request('pathname_to_str')
    return
      function(path_name)
        return pathname_to_str(pathname_from_str(path_name))
      end
  end
package.preload['workshop.concepts.path_name.is_absolute'] =
  function(...)
    return
      function(Pathname)
        return (Pathname[1] == '')
      end
  end
package.preload['workshop.concepts.path_name.is_directory'] =
  function(...)
    local self_dir
    local upper_dir
    do
      local Syntels = request('Syntels')
      self_dir = Syntels.self_dir
      upper_dir = Syntels.upper_dir
    end
    return
      function(Pathname)
        local last_node = Pathname[#Pathname]
        return
          (last_node == '') or
          (last_node == self_dir) or
          (last_node == upper_dir)
      end
  end
package.preload['workshop.concepts.path_name.Syntels'] =
  function(...)
    return { separator = '/', self_dir = '.', upper_dir = '..' }
  end
package.preload['callgraph.get_next_ones'] =
  function(...)
    local get_next_offs
    do
      local use_vm_2015
      local use_vm_2020
      do
        local is_lua_53 = (_VERSION == 'Lua 5.3')
        local is_lua_54 = (_VERSION == 'Lua 5.4')
        local is_lua_55 = (_VERSION == 'Lua 5.5')
        use_vm_2015 = is_lua_53
        use_vm_2020 = is_lua_54 or is_lua_55
      end
      if use_vm_2015 then
        get_next_offs = request('vm_2015.get_next_offs')
      elseif use_vm_2020 then
        get_next_offs = request('vm_2020.get_next_offs')
      end
    end
    local add_to_list = request('!.concepts.list.add_item')
    return
      function(instruction_index, Instruction)
        local NextOffs = get_next_offs(Instruction)
        local NextOnes = {}
        for _, offs in ipairs(NextOffs) do
          add_to_list(NextOnes, instruction_index + offs)
        end
        return NextOnes
      end
  end
package.preload['callgraph.callgraph_to_tgf'] =
  function(...)
    local AsciiChars = request('!.concepts.Ascii.Chars')
    local IndexSerializer = request('!.concepts.PaddedIndex')
    local OutputStream
    local write_rec
    do
      local field_separator = AsciiChars.space
      local record_separator = AsciiChars.newline
      local list_to_str = request('!.concepts.list.to_string')
      write_rec =
        function(Rec)
          OutputStream:Write(
            list_to_str(Rec, field_separator) .. record_separator
          )
        end
    end
    local write_empty_line =
      function()
        write_rec({})
      end
    local write_label =
      function(name, label)
        write_rec({ name, label })
      end
    local write_sections_delimiter
    do
      local parts_delim = AsciiChars.number_sign
      write_sections_delimiter =
        function()
          write_rec({ parts_delim })
        end
    end
    local write_link =
      function(src_name, dest_name)
        write_rec({ src_name, dest_name })
      end
    local get_node_name =
      function(index)
        return IndexSerializer:ToString(index)
      end
    return
      function(InstructionsGraph, Arg_OutputStream)
        IndexSerializer = IndexSerializer.create(#InstructionsGraph)
        OutputStream = Arg_OutputStream
        for
          instruction_index, Instruction in ipairs(InstructionsGraph)
        do
          write_label(
            get_node_name(instruction_index), Instruction.label
          )
        end
        write_empty_line()
        write_sections_delimiter()
        write_empty_line()
        for
          src_instruction_index, Instruction in
            ipairs(InstructionsGraph)
        do
          local src_name = get_node_name(src_instruction_index)
          local NextOnes = Instruction.NextOnes
          local is_forking_node = (#NextOnes > 1)
          if is_forking_node then
            write_empty_line()
          end
          for _, dest_instruction_index in ipairs(NextOnes) do
            write_link(src_name, get_node_name(dest_instruction_index))
          end
          if is_forking_node then
            write_empty_line()
          end
        end
      end
  end
package.preload['callgraph.get_chains'] =
  function(...)
    local add_to_list = request('!.concepts.list.add_item')
    return
      function(InstructionsGraph)
        local num_instructions = #InstructionsGraph
        local Chains = {}
        local VisitedNodes_Map = {}
        for i = 1, num_instructions do
          VisitedNodes_Map[i] = false
        end
        local walk_chain
        walk_chain =
          function(start_node, Chain)
            add_to_list(Chain, start_node)
            if VisitedNodes_Map[start_node] then
              add_to_list(Chains, Chain)
              return
            end
            VisitedNodes_Map[start_node] = true
            local NextOnes = InstructionsGraph[start_node].NextOnes
            local num_next_ones = #NextOnes
            if (num_next_ones == 0) then
              add_to_list(Chains, Chain)
              return
            end
            walk_chain(NextOnes[1], Chain)
            for next_one_index = 2, num_next_ones do
              local InnerChain = { start_node }
              walk_chain(NextOnes[next_one_index], InnerChain)
            end
          end
        for start_node = 1, num_instructions do
          if not VisitedNodes_Map[start_node] then
            walk_chain(start_node, {})
          end
        end
        return Chains
      end
  end
package.preload['callgraph.callgraph_to_dot'] =
  function(...)
    local Writer = request('callgraph_to_dot.Writer')
    local get_chains = request('get_chains')
    return
      function(InstructionsGraph, OutputStream)
        local Writer = Writer.create(OutputStream, #InstructionsGraph)
        Writer:StartGraph()
        for
          instruction_index, Instruction in ipairs(InstructionsGraph)
        do
          Writer:Node(instruction_index, Instruction.label)
        end
        Writer:EmptyLine()
        for _, Chain in ipairs(get_chains(InstructionsGraph)) do
          Writer:Chain(Chain)
        end
        Writer:EndGraph()
      end
  end
package.preload['callgraph.callgraph_to_mmd'] =
  function(...)
    local Writer = request('callgraph_to_mmd.Writer')
    local get_chains = request('get_chains')
    return
      function(InstructionsGraph, OutputStream)
        local Writer = Writer.create(OutputStream, #InstructionsGraph)
        Writer:StartGraph()
        for
          instruction_index, Instruction in ipairs(InstructionsGraph)
        do
          Writer:Node(instruction_index, Instruction.label)
        end
        Writer:EmptyLine()
        for _, Chain in ipairs(get_chains(InstructionsGraph)) do
          Writer:Chain(Chain)
        end
        Writer:EndGraph()
      end
  end
package.preload['callgraph.vm_2020.FlowOpcodes'] =
  function(...)
    return
      {
        [1] = { 'TAILCALL', 'RETURN', 'RETURN0', 'RETURN1' },
        [2] = 'LFALSESKIP',
        [3] = 'JMP',
        [4] = 'TFORPREP',
        [5] =
          {
            'ADDI',
            'ADDK',
            'SUBK',
            'MULK',
            'MODK',
            'POWK',
            'DIVK',
            'IDIVK',
            'BANDK',
            'BORK',
            'BXORK',
            'SHRI',
            'SHLI',
            'ADD',
            'SUB',
            'MUL',
            'MOD',
            'POW',
            'DIV',
            'IDIV',
            'BAND',
            'BOR',
            'BXOR',
            'SHL',
            'SHR',
            'EQ',
            'LT',
            'LE',
            'EQK',
            'EQI',
            'LTI',
            'LEI',
            'GTI',
            'GEI',
            'TEST',
            'TESTSET',
          },
        [6] = { 'FORLOOP', 'TFORLOOP' },
        [7] = 'FORPREP',
      }
  end
package.preload['callgraph.vm_2020.get_next_offs'] =
  function(...)
    local Terminators_Map
    local opcode_lfalseskip
    local opcode_jmp
    local opcode_tforprep
    local BasicForks_Map
    local Loopbacks_Map
    local opcode_forprep
    do
      local FlowOpcodes = request('FlowOpcodes')
      local map_values = request('!.table.map_values')
      Terminators_Map = map_values(FlowOpcodes[1])
      opcode_lfalseskip = FlowOpcodes[2]
      opcode_jmp = FlowOpcodes[3]
      opcode_tforprep = FlowOpcodes[4]
      BasicForks_Map = map_values(FlowOpcodes[5])
      Loopbacks_Map = map_values(FlowOpcodes[6])
      opcode_forprep = FlowOpcodes[7]
    end
    local add_to_list = request('!.concepts.list.add_item')
    return
      function(Instruction)
        local NextOffs = {}
        local opcode = Instruction[1]
        if Terminators_Map[opcode] then
          ;
        elseif (opcode == opcode_lfalseskip) then
          add_to_list(NextOffs, 2)
        elseif (opcode == opcode_jmp) then
          add_to_list(NextOffs, tonumber(Instruction[2]) + 1)
        elseif (opcode == opcode_tforprep) then
          add_to_list(NextOffs, tonumber(Instruction[3]) + 1)
        elseif BasicForks_Map[opcode] then
          add_to_list(NextOffs, 1)
          add_to_list(NextOffs, 2)
        elseif Loopbacks_Map[opcode] then
          add_to_list(NextOffs, -tonumber(Instruction[3]) + 1)
          add_to_list(NextOffs, 1)
        elseif (opcode == opcode_forprep) then
          add_to_list(NextOffs, 1)
          add_to_list(NextOffs, tonumber(Instruction[3]) + 2)
        else
          add_to_list(NextOffs, 1)
        end
        return NextOffs
      end
  end
package.preload['callgraph.callgraph_to_mmd.Spaces'] =
  function(...)
    local AsciiChars = request('!.concepts.Ascii.Chars')
    return { space = AsciiChars.space, newline = AsciiChars.newline }
  end
package.preload['callgraph.callgraph_to_mmd.Syntels'] =
  function(...)
    local AsciiChars = request('!.concepts.Ascii.Chars')
    return
      {
        kw_flowchart = 'flowchart',
        topdown = 'TD',
        arrow = '-->',
        quote = AsciiChars.double_quote,
        end_statement = AsciiChars.newline,
        start_attr = AsciiChars.opening_bracket,
        end_attr = AsciiChars.closing_bracket,
      }
  end
package.preload['callgraph.callgraph_to_mmd.TokensOutputStream'] =
  function(...)
    local Spaces = request('Spaces')
    local Syntels = request('Syntels')
    local end_line
    local empty_line
    do
      local line_separator = Spaces.newline
      end_line =
        function(Me)
          if (Me[2] == 0) then
            return
          end
          Me[1]:Write(line_separator)
          Me[2] = 0
          Me[3] = ''
        end
      empty_line =
        function(Me)
          end_line(Me)
          Me[1]:Write(line_separator)
        end
    end
    local write
    do
      local item_separator = Spaces.space
      local sep_len = #item_separator
      local is_alnum = request('!.concepts.Ascii.is_alnum')
      local str_sub = string.sub
      local str_byte = string.byte
      local ends_with = request('!.string.ends_with')
      local wrapping_len = 53
      local arrow = Syntels.arrow
      local end_statement = Syntels.end_statement
      local kw_flowchart = Syntels.kw_flowchart
      write =
        function(Me, token)
          local OutputStream = Me[1]
          local line_len = Me[2]
          local prev_token = Me[3]
          local Indent = Me[4]
          if (line_len == 0) then
            OutputStream:Write(Indent:ToString())
          end
          if (line_len > wrapping_len) and (token == arrow) then
            end_line(Me)
            OutputStream:Write(Indent:ToString())
            OutputStream:Write(prev_token)
          end
          do
            local write_sep = false
            if (prev_token ~= '') then
              local prev_char_code =
                str_byte(str_sub(prev_token, -1, -1))
              local next_char_code = str_byte(str_sub(token, 1, 1))
              write_sep =
                (is_alnum(prev_char_code) and is_alnum(next_char_code)) or
                ((prev_token == arrow) or (token == arrow))
            end
            if write_sep then
              OutputStream:Write(item_separator)
              Me[2] = Me[2] + sep_len
            end
          end
          OutputStream:Write(token)
          if (token == kw_flowchart) then
            Indent:Inc()
          end
          Me[2] = Me[2] + #token
          Me[3] = token
        end
    end
    local Interface
    do
      local create
      do
        local IndentClass = request('!.concepts.Indent')
        local indent_chunk = '  '
        local attach_methods = request('!.table.attach_methods')
        create =
          function(BaseOutputStream)
            assert_table(BaseOutputStream)
            local Indent = IndentClass.create()
            Indent:SetIndentChunk(indent_chunk)
            local Core =
              {
                [1] = BaseOutputStream,
                [2] = 0,
                [3] = '',
                [4] = Indent,
              }
            attach_methods(Core, Interface)
            return Core
          end
      end
      Interface =
        {
          create = create,
          EndLine = end_line,
          EmptyLine = empty_line,
          Write = write,
        }
    end
    return Interface
  end
package.preload['callgraph.callgraph_to_mmd.Writer'] =
  function(...)
    local Syntels = request('Syntels')
    local EmptyLine =
      function(Me)
        Me[1]:EmptyLine()
      end
    local quote
    do
      local quote_str = Syntels.quote
      quote =
        function(str)
          return quote_str .. str .. quote_str
        end
    end
    local StartGraph
    do
      local flowchart = Syntels.kw_flowchart
      local topdown = Syntels.topdown
      StartGraph =
        function(Me)
          local Tokens = Me[1]
          Tokens:Write(flowchart)
          Tokens:Write(topdown)
          Tokens:EndLine()
        end
    end
    local EndGraph =
      function(Me)
        Me[1]:EndLine()
      end
    local get_node_name
    do
      local name_prefix = '_'
      get_node_name =
        function(Me, index)
          return name_prefix .. Me[2]:ToString(index)
        end
    end
    local Node
    do
      local start_attr = Syntels.start_attr
      local end_attr = Syntels.end_attr
      Node =
        function(Me, index, label)
          local Tokens = Me[1]
          Tokens:Write(get_node_name(Me, index))
          Tokens:Write(start_attr)
          Tokens:Write(quote(label))
          Tokens:Write(end_attr)
          Tokens:EndLine()
        end
    end
    local Chain
    do
      local arrow = Syntels.arrow
      Chain =
        function(Me, Chain)
          local Tokens = Me[1]
          local num_nodes = #Chain
          if (num_nodes <= 1) then
            return
          end
          Tokens:Write(get_node_name(Me, Chain[1]))
          for node_idx = 2, num_nodes do
            Tokens:Write(arrow)
            Tokens:Write(get_node_name(Me, Chain[node_idx]))
          end
          Tokens:EndLine()
        end
    end
    local Methods
    do
      local create
      do
        local attach_methods = request('!.table.attach_methods')
        local TokensWriter = request('TokensOutputStream')
        local IndexSerializer = request('!.concepts.PaddedIndex')
        create =
          function(OutputStream, num_nodes)
            local Core =
              {
                [1] = TokensWriter.create(OutputStream),
                [2] = IndexSerializer.create(num_nodes),
              }
            attach_methods(Core, Methods)
            return Core
          end
      end
      Methods =
        {
          create = create,
          EmptyLine = EmptyLine,
          StartGraph = StartGraph,
          EndGraph = EndGraph,
          Node = Node,
          Chain = Chain,
        }
    end
    return Methods
  end
package.preload['callgraph.vm_2015.FlowOpcodes'] =
  function(...)
    return
      {
        [1] = { 'TAILCALL', 'RETURN' },
        [2] = 'JMP',
        [3] = { 'EQ', 'LT', 'LE', 'TEST', 'TESTSET' },
        [4] = { 'FORLOOP', 'TFORLOOP' },
        [5] = 'FORPREP',
      }
  end
package.preload['callgraph.vm_2015.get_next_offs'] =
  function(...)
    local Terminators_Map
    local opcode_jmp
    local BasicForks_Map
    local Loopbacks_Map
    local opcode_forprep
    do
      local FlowOpcodes = request('FlowOpcodes')
      local map_values = request('!.table.map_values')
      Terminators_Map = map_values(FlowOpcodes[1])
      opcode_jmp = FlowOpcodes[2]
      BasicForks_Map = map_values(FlowOpcodes[3])
      Loopbacks_Map = map_values(FlowOpcodes[4])
      opcode_forprep = FlowOpcodes[5]
    end
    local add_to_list = request('!.concepts.list.add_item')
    return
      function(Instruction)
        local NextOffs = {}
        local opcode = Instruction[1]
        if Terminators_Map[opcode] then
          ;
        elseif (opcode == opcode_jmp) then
          add_to_list(NextOffs, tonumber(Instruction[3]) + 1)
        elseif BasicForks_Map[opcode] then
          add_to_list(NextOffs, 1)
          add_to_list(NextOffs, 2)
        elseif Loopbacks_Map[opcode] then
          add_to_list(NextOffs, tonumber(Instruction[3]) + 1)
          add_to_list(NextOffs, 1)
        elseif (opcode == opcode_forprep) then
          add_to_list(NextOffs, tonumber(Instruction[3]) + 1)
        else
          add_to_list(NextOffs, 1)
        end
        return NextOffs
      end
  end
package.preload['callgraph.callgraph_to_dot.Spaces'] =
  function(...)
    local AsciiChars = request('!.concepts.Ascii.Chars')
    return
      {
        space = AsciiChars.space,
        tab = AsciiChars.tab,
        newline = AsciiChars.newline,
      }
  end
package.preload['callgraph.callgraph_to_dot.Syntels'] =
  function(...)
    local AsciiChars = request('!.concepts.Ascii.Chars')
    return
      {
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
  end
package.preload['callgraph.callgraph_to_dot.TokensOutputStream'] =
  function(...)
    local Spaces = request('Spaces')
    local Syntels = request('Syntels')
    local end_line
    local empty_line
    do
      local line_separator = Spaces.newline
      end_line =
        function(Me)
          if (Me[2] == 0) then
            return
          end
          Me[1]:Write(line_separator)
          Me[2] = 0
          Me[3] = ''
        end
      empty_line =
        function(Me)
          end_line(Me)
          Me[1]:Write(line_separator)
        end
    end
    local write
    do
      local item_separator = Spaces.space
      local sep_len = #item_separator
      local is_alnum = request('!.concepts.Ascii.is_alnum')
      local str_sub = string.sub
      local str_byte = string.byte
      local ends_with = request('!.string.ends_with')
      local wrapping_len = 53
      local arrow = Syntels.arrow
      local end_statement = Syntels.end_statement
      local start_graph = Syntels.start_graph
      local end_graph = Syntels.end_graph
      write =
        function(Me, token)
          local OutputStream = Me[1]
          local line_len = Me[2]
          local prev_token = Me[3]
          local Indent = Me[4]
          if (token == end_graph) then
            Indent:Dec()
          end
          if (line_len == 0) then
            OutputStream:Write(Indent:ToString())
          end
          if
            (line_len > wrapping_len) and
            ((prev_token == arrow) or (prev_token == end_statement))
          then
            end_line(Me)
            OutputStream:Write(Indent:ToString())
            OutputStream:Write(Indent:GetIndentChunk())
          else
            local write_sep = false
            if (prev_token ~= '') then
              local prev_char_code =
                str_byte(str_sub(prev_token, -1, -1))
              local next_char_code = str_byte(str_sub(token, 1, 1))
              write_sep =
                (is_alnum(prev_char_code) and is_alnum(next_char_code)) or
                (
                  (token ~= end_statement) and
                  not ends_with(prev_token, item_separator)
                )
            end
            if write_sep then
              OutputStream:Write(item_separator)
              Me[2] = Me[2] + sep_len
            end
          end
          OutputStream:Write(token)
          if (token == start_graph) then
            Indent:Inc()
          end
          Me[2] = Me[2] + #token
          Me[3] = token
        end
    end
    local Interface
    do
      local create
      do
        local IndentClass = request('!.concepts.Indent')
        local indent_chunk = '   '
        local attach_methods = request('!.table.attach_methods')
        create =
          function(BaseOutputStream)
            assert_table(BaseOutputStream)
            local Indent = IndentClass.create()
            Indent:SetIndentChunk(indent_chunk)
            local Core =
              {
                [1] = BaseOutputStream,
                [2] = 0,
                [3] = '',
                [4] = Indent,
              }
            attach_methods(Core, Interface)
            return Core
          end
      end
      Interface =
        {
          create = create,
          EndLine = end_line,
          EmptyLine = empty_line,
          Write = write,
        }
    end
    return Interface
  end
package.preload['callgraph.callgraph_to_dot.Writer'] =
  function(...)
    local Syntels = request('Syntels')
    local EmptyLine =
      function(Me)
        Me[1]:EmptyLine()
      end
    local quote
    do
      local quote_str = Syntels.quote
      quote =
        function(str)
          return quote_str .. str .. quote_str
        end
    end
    local StartGraph
    do
      local digraph = Syntels.kw_digraph
      local start_graph = Syntels.start_graph
      StartGraph =
        function(Me, graph_name)
          local Tokens = Me[1]
          Tokens:Write(digraph)
          if graph_name then
            Tokens:Write(quote(graph_name))
          end
          Tokens:EndLine()
          Tokens:Write(start_graph)
          Tokens:EndLine()
        end
    end
    local EndGraph
    do
      local end_graph = Syntels.end_graph
      EndGraph =
        function(Me)
          local Tokens = Me[1]
          Tokens:EndLine()
          Tokens:Write(end_graph)
          Tokens:EndLine()
        end
    end
    local get_node_name
    do
      local name_prefix = '_'
      get_node_name =
        function(Me, index)
          return name_prefix .. Me[2]:ToString(index)
        end
    end
    local Node
    do
      local start_attr = Syntels.start_attr
      local end_attr = Syntels.end_attr
      local label_kw = Syntels.kw_label
      local assign = Syntels.assign
      local end_statement = Syntels.end_statement
      Node =
        function(Me, index, label)
          local Tokens = Me[1]
          Tokens:Write(get_node_name(Me, index))
          Tokens:Write(start_attr)
          Tokens:Write(label_kw)
          Tokens:Write(assign)
          Tokens:Write(quote(label))
          Tokens:Write(end_attr)
          Tokens:Write(end_statement)
          Tokens:EndLine()
        end
    end
    local Chain
    do
      local arrow = Syntels.arrow
      local end_statement = Syntels.end_statement
      Chain =
        function(Me, Chain)
          local Tokens = Me[1]
          local num_nodes = #Chain
          if (num_nodes <= 1) then
            return
          end
          Tokens:Write(get_node_name(Me, Chain[1]))
          for node_idx = 2, num_nodes do
            Tokens:Write(arrow)
            Tokens:Write(get_node_name(Me, Chain[node_idx]))
          end
          Tokens:Write(end_statement)
          Tokens:EndLine()
        end
    end
    local Methods
    do
      local create
      do
        local attach_methods = request('!.table.attach_methods')
        local TokensWriter = request('TokensOutputStream')
        local IndexSerializer = request('!.concepts.PaddedIndex')
        create =
          function(OutputStream, num_nodes)
            local Core =
              {
                [1] = TokensWriter.create(OutputStream),
                [2] = IndexSerializer.create(num_nodes),
              }
            attach_methods(Core, Methods)
            return Core
          end
      end
      Methods =
        {
          create = create,
          EmptyLine = EmptyLine,
          StartGraph = StartGraph,
          EndGraph = EndGraph,
          Node = Node,
          Chain = Chain,
        }
    end
    return Methods
  end
return require('generate_callgraphs_lua')