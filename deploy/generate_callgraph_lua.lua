_G.package.preload['run'] =
  function(...)
    package.path = package.path .. ';../../?.lua'
    require('workshop.base')
    local get_chunks
    do
      local file_to_str = request('!.convert.file_to_str')
      local get_bytecode =
        request(
          '!.concepts.lua_bytecode_decompiler.bytecode_from_source'
        )
      local get_listing =
        request(
          '!.concepts.lua_bytecode_decompiler.listing_from_bytecode'
        )
      get_chunks =
        function(source_code_file_name)
          return
            get_listing(
              get_bytecode(file_to_str(source_code_file_name))
            )
        end
    end
    local get_callgraph
    do
      local space = ' '
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
    do
      local OutputFileStream =
        request('!.concepts.StreamIo.Output.File')
      local callgraph_to_tgf = request('callgraph.callgraph_to_tgf')
      export_to_tgf =
        function(Callgraph, file_name)
          local OutputStream = new(OutputFileStream)
          OutputStream:Open(file_name)
          callgraph_to_tgf(Callgraph, OutputStream)
          OutputStream:Close()
        end
    end
    local export_to_dot
    do
      local OutputFileStream =
        request('!.concepts.StreamIo.Output.File')
      local callgraph_to_dot = request('callgraph.callgraph_to_dot')
      export_to_dot =
        function(Callgraph, graph_name, file_name)
          local OutputStream = new(OutputFileStream)
          OutputStream:Open(file_name)
          callgraph_to_dot(Callgraph, graph_name, OutputStream)
          OutputStream:Close()
        end
    end
    local usage_text =
      [[

Creates call graphs for Lua code.

Usage: <lua_file_name> <output_dir>

-- Martin, 2026-07
]]
    local Config =
      {
        source_code_file_name = arg[1],
        output_dir_name = arg[2],
        do_export_to_tgf = true,
        do_export_to_dot = true,
      }
    do
      local source_code_file_name = Config.source_code_file_name
      local output_dir_name = Config.output_dir_name
      local do_export_to_tgf = Config.do_export_to_tgf
      local do_export_to_dot = Config.do_export_to_dot
      if not (source_code_file_name and output_dir_name) then
        io.stdout:write(usage_text)
        return
      end
      local tgf_name_format = 'output/callgraph_%d.tgf'
      local dot_name_format = 'output/callgraph_%d.dot'
      local str_format = string.format
      local Chunks = get_chunks(source_code_file_name)
      for chunk_index, Chunk in ipairs(Chunks) do
        local Callgraph = get_callgraph(Chunk)
        if do_export_to_tgf then
          local file_name = str_format(tgf_name_format, chunk_index)
          export_to_tgf(Callgraph, file_name)
        end
        if do_export_to_dot then
          local graph_name = 'Callgraph_' .. chunk_index
          local file_name = str_format(dot_name_format, chunk_index)
          export_to_dot(Callgraph, graph_name, file_name)
        end
      end
    end
  end
_G.package.preload['workshop.base'] =
  function(...)
    local split_name =
      function(qualified_name)
        local prefix_name_pattern = '^(.+%.)([^%.]+)$'
        local prefix, name =
          string.match(qualified_name, prefix_name_pattern)
        if not prefix then
          prefix = ''
          if string.find(qualified_name, '%.') then
            name = ''
          else
            name = qualified_name
          end
        end
        return prefix, name
      end
    local unite_prefixes =
      function(base_prefix, rel_prefix)
        local uplevel_capture = '(.+%.)[^%.]-%.$'
        while (string.sub(rel_prefix, 1, 2) == '^.') do
          if (base_prefix == '') then
            error("Link is outside of caller's prefix.")
          end
          base_prefix = string.match(base_prefix, uplevel_capture) or ''
          rel_prefix = string.sub(rel_prefix, 3)
        end
        return base_prefix .. rel_prefix
      end
    local Names = {}
    local depth = 1
    local get_caller_prefix =
      function()
        local NameRec = Names[depth]
        if not NameRec then
          return ''
        end
        return NameRec.prefix
      end
    local get_caller_name =
      function()
        local NameRec = Names[depth]
        if not NameRec then
          return 'anonymous'
        end
        return NameRec.prefix .. NameRec.name
      end
    local push =
      function(prefix, name)
        depth = depth + 1
        Names[depth] = { prefix = prefix, name = name }
      end
    local pop =
      function()
        depth = depth - 1
      end
    local Dependencies_Map = {}
    local add_dependency =
      function(src_name, dest_name)
        Dependencies_Map[src_name] = Dependencies_Map[src_name] or {}
        Dependencies_Map[src_name][dest_name] = true
      end
    local base_prefix = split_name((...))
    local get_require_name =
      function(qualified_name)
        local caller_prefix
        local is_absolute_name =
          (string.sub(qualified_name, 1, 2) == '!.')
        if is_absolute_name then
          qualified_name = string.sub(qualified_name, 3)
          caller_prefix = base_prefix
        else
          caller_prefix = get_caller_prefix()
        end
        local prefix, name = split_name(qualified_name)
        prefix = unite_prefixes(caller_prefix, prefix)
        return prefix .. name, prefix, name
      end
    local request =
      function(qualified_name)
        local src_name = get_caller_name()
        local require_name, prefix, name =
          get_require_name(qualified_name)
        push(prefix, name)
        local dest_name = get_caller_name()
        add_dependency(src_name, dest_name)
        local Results = table.pack(require(require_name))
        pop()
        return table.unpack(Results)
      end
    local is_first_run = (_G.request == nil)
    if is_first_run then
      _G.request = request
      _G.get_dependencies =
        function()
          return Dependencies_Map
        end
      _G.get_base_prefix =
        function()
          return base_prefix
        end
      _G.get_require_name = get_require_name
      local our_require_name = (...)
      push('', our_require_name)
      request('!.system.install_is_functions')()
      request('!.system.install_assert_functions')()
      _G.new = request('!.table.new')
      pop()
    end
  end
_G.package.preload['workshop.system.install_is_functions'] =
  function(...)
    local TypeNames = request('!.concepts.lua.TypeNames')
    local NumberTypeNames = request('!.concepts.lua.NumberTypeNames')
    local type_is =
      function(type_name)
        return
          function(val)
            return (type(val) == type_name)
          end
      end
    local number_is =
      function(type_name)
        return
          function(val)
            if not is_number(val) then
              return false
            end
            return (math.type(val) == type_name)
          end
      end
    local install_is_functions =
      function()
        for _, type_name in ipairs(TypeNames) do
          _G['is_' .. type_name] = type_is(type_name)
        end
        for _, math_type_name in ipairs(NumberTypeNames) do
          _G['is_' .. math_type_name] = number_is(math_type_name)
        end
      end
    return install_is_functions
  end
_G.package.preload['workshop.system.install_assert_functions'] =
  function(...)
    local TypeNames = request('!.concepts.lua.TypeNames')
    local NumberTypeNames = request('!.concepts.lua.NumberTypeNames')
    local spawn_assert_func =
      function(type_name)
        local checker = _G['is_' .. type_name]
        assert(checker)
        return
          function(val)
            if not checker(val) then
              local err_msg =
                string.format('assert_%s(%s)', type_name, tostring(val))
              error(err_msg)
            end
          end
      end
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
_G.package.preload['workshop.lua.regexp.magic_chars'] =
  function(...)
    return '^$()[]%.?*+-'
  end
_G.package.preload['workshop.lua.regexp.magic_char_pattern'] =
  function(...)
    local magic_chars = request('magic_chars')
    local magic_char_patttern =
      '[' .. magic_chars:gsub('.', '%%%0') .. ']'
    return magic_char_patttern
  end
_G.package.preload['workshop.lua.regexp.quote'] =
  function(...)
    local magic_char_pattern = request('magic_char_pattern')
    return
      function(s)
        return s:gsub(magic_char_pattern, '%%%0')
      end
  end
_G.package.preload[
  'workshop.mechs.cmdline.get_cmd_decompile_lua_bytecode'
] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local quote = request('!.concepts.shell.quote')
    local glue_words = request('!.concepts.words.to_string')
    local get_cmd_decompile_lua_bytecode =
      function(bytecode_file_name)
        bytecode_file_name = normalize(bytecode_file_name)
        local Command =
          { 'luac', '-l', '-p', quote(bytecode_file_name) }
        return glue_words(Command)
      end
    return get_cmd_decompile_lua_bytecode
  end
_G.package.preload[
  'workshop.mechs.cmdline.get_cmd_execute_with_redirects'
] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local quote = request('!.concepts.shell.quote')
    local glue_words = request('!.concepts.words.to_string')
    return
      function(orig_command, output_file_name, errors_file_name)
        local Command =
          {
            'sh',
            '-c',
            quote(orig_command),
            '1>' .. quote(normalize(output_file_name)),
            '2>' .. quote(normalize(errors_file_name)),
          }
        return glue_words(Command)
      end
  end
_G.package.preload['workshop.mechs.cmdline.get_cmd_rmfile'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local quote = request('!.concepts.shell.quote')
    local glue_words = request('!.concepts.words.to_string')
    return
      function(file_name)
        local Command = { 'rm', quote(normalize(file_name)) }
        return glue_words(Command)
      end
  end
_G.package.preload['workshop.number.is_natural'] =
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
_G.package.preload['workshop.number.get_num_dec_digits'] =
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
_G.package.preload['workshop.table.clone'] =
  function(...)
    local cloned = {}
    local clone
    clone =
      function(node)
        if (type(node) == 'table') then
          if cloned[node] then
            return cloned[node]
          else
            local result = {}
            cloned[node] = result
            for k, v in pairs(node) do
              result[clone(k)] = clone(v)
            end
            setmetatable(result, getmetatable(node))
            return result
          end
        else
          return node
        end
      end
    return
      function(node)
        cloned = {}
        return clone(node)
      end
  end
_G.package.preload['workshop.table.new'] =
  function(...)
    local clone = request('clone')
    local patch = request('patch')
    return
      function(base_obj, overriden_params)
        assert_table(base_obj)
        local result = clone(base_obj)
        if is_table(overriden_params) then
          patch(result, overriden_params)
        end
        return result
      end
  end
_G.package.preload['workshop.table.patch'] =
  function(...)
    local apply_table = request('apply_table')
    local Rules = { { has_a = true, has_b = true, action = 'replace' } }
    local patch =
      function(Result, Additions)
        apply_table(Result, Additions, Rules)
      end
    return patch
  end
_G.package.preload['workshop.table.map_values'] =
  function(...)
    local map_values =
      function(List)
        assert_table(List)
        local Result = {}
        for _, value in pairs(List) do
          Result[value] = true
        end
        return Result
      end
    return map_values
  end
_G.package.preload['workshop.table.apply_table'] =
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
    local apply_table_root =
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
    return apply_table_root
  end
_G.package.preload['workshop.file_system.file.open'] =
  function(...)
    local normalize_name = request('!.concepts.path_name.normalize')
    local default_mode = 'rb'
    local open_file =
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
    return open_file
  end
_G.package.preload['workshop.file_system.file.open_for_writing'] =
  function(...)
    local open_file = request('open')
    local open_for_writing =
      function(pathname)
        return open_file(pathname, 'w+b')
      end
    return open_for_writing
  end
_G.package.preload['workshop.file_system.file.close'] =
  function(...)
    local close =
      function(File)
        local file_type = io.type(File)
        if not is_string(file_type) then
          return
        end
        if (file_type == 'closed file') then
          return
        end
        io.close(File)
      end
    return close
  end
_G.package.preload['workshop.file_system.file.create'] =
  function(...)
    local open_file = request('open')
    local create_file =
      function(pathname, contents)
        assert_string(pathname)
        assert_string(contents)
        local file = open_file(pathname, 'wb')
        file:write(contents)
        file:close()
      end
    return create_file
  end
_G.package.preload['workshop.file_system.file.to_string'] =
  function(...)
    local open_file = request('open')
    local load_file_contents =
      function(pathname)
        local File = open_file(pathname, 'rb')
        local result = File:read('a')
        File:close()
        return result
      end
    return load_file_contents
  end
_G.package.preload['workshop.file_system.file.exists'] =
  function(...)
    local normalize_name = request('!.concepts.path_name.normalize')
    local pathname_exists =
      function(pathname)
        assert_string(pathname)
        pathname = normalize_name(pathname)
        local file = io.open(pathname, 'rb')
        local result = not is_nil(file)
        if result then
          file:close()
        end
        return result
      end
    return pathname_exists
  end
_G.package.preload['workshop.file_system.file.remove'] =
  function(...)
    local file_exists = request('exists')
    local get_rmfile_command = request('!.mechs.cmdline.get_cmd_rmfile')
    local shell_execute = request('!.concepts.shell.execute')
    local remove_file =
      function(pathname)
        assert_string(pathname)
        if not file_exists(pathname) then
          return true
        end
        local remove_file_cmd = get_rmfile_command(pathname)
        shell_execute(remove_file_cmd)
        if not file_exists(pathname) then
          return true
        end
        return false
      end
    return remove_file
  end
_G.package.preload['workshop.string.trim'] =
  function(...)
    local trim_head = request('trim_head')
    local trim_tail = request('trim_tail')
    return
      function(s)
        return trim_head(trim_tail(s))
      end
  end
_G.package.preload['workshop.string.starts_with'] =
  function(...)
    local quote_regexp = request('!.lua.regexp.quote')
    local starts_with =
      function(base_str, prefix_str)
        local prefix_pattern = '^' .. quote_regexp(prefix_str)
        local start_pos = string.find(base_str, prefix_pattern)
        local result = is_number(start_pos)
        return result
      end
    return starts_with
  end
_G.package.preload['workshop.string.trim_tail'] =
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
_G.package.preload['workshop.string.ends_with'] =
  function(...)
    local quote_regexp = request('!.lua.regexp.quote')
    local ends_with =
      function(base_str, postfix_str)
        local postfix_pattern = quote_regexp(postfix_str) .. '$'
        local start_pos = string.find(base_str, postfix_pattern)
        local result = is_number(start_pos)
        return result
      end
    return ends_with
  end
_G.package.preload['workshop.string.trim_head'] =
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
_G.package.preload['workshop.string.split'] =
  function(...)
    local ends_with = request('!.string.ends_with')
    local quote_regexp = request('!.lua.regexp.quote')
    local add_to_list = request('!.concepts.list.add_item')
    local split_string =
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
            string.find(str, item_capture, start_pos)
          if not start_pos then
            break
          end
          add_to_list(Result, item_str)
          start_pos = end_pos + 1
        end
        return Result
      end
    return split_string
  end
_G.package.preload['workshop.convert.file_to_str'] =
  function(...)
    return request('!.file_system.file.to_string')
  end
_G.package.preload['workshop.convert.file_from_str'] =
  function(...)
    local create_file_with_contents =
      request('!.file_system.file.create')
    local save_str_to_file =
      function(str, file_name)
        create_file_with_contents(file_name, str)
      end
    return save_str_to_file
  end
_G.package.preload['workshop.concepts.lua.NumberTypeNames'] =
  function(...)
    local NumberTypeNames = { 'integer', 'float' }
    return NumberTypeNames
  end
_G.package.preload['workshop.concepts.lua.TypeNames'] =
  function(...)
    local TypeNames =
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
    return TypeNames
  end
_G.package.preload['workshop.concepts.shell.split_shebang'] =
  function(...)
    local starts_with = request('!.string.starts_with')
    local str_find = string.find
    local str_sub = string.sub
    local shebang_prefix = '#!'
    local newline = '\010'
    local split_shebang =
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
    return split_shebang
  end
_G.package.preload['workshop.concepts.shell.quote'] =
  function(...)
    local list_to_str = request('!.concepts.list.to_string')
    local split_string = request('!.string.split')
    local add_to_list = request('!.concepts.list.add_item')
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
    local needs_quoting =
      function(str)
        return
          (str == '') or
          not is_nil(string.find(str, special_chars_regexp)) or
          not is_nil(string.find(str, starts_with_comment_regexp))
      end
    local quote
    quote =
      function(str)
        assert_string(str)
        if not needs_quoting(str) then
          return str
        end
        local single_quote = "'"
        if not string.find(str, single_quote) then
          return single_quote .. str .. single_quote
        end
        str = str .. single_quote
        local RawItems = split_string(str, single_quote)
        local Items = {}
        for _, item in ipairs(RawItems) do
          local quoted_item
          if (item == '') then
            quoted_item = ''
          else
            quoted_item = quote(item)
          end
          add_to_list(Items, quoted_item)
        end
        return list_to_str(Items, [[\]] .. single_quote)
      end
    return quote
  end
_G.package.preload['workshop.concepts.shell.execute'] =
  function(...)
    local file_to_str = request('!.convert.file_to_str')
    local get_execute_command =
      request('!.mechs.cmdline.get_cmd_execute_with_redirects')
    local execute_shell_command =
      function(command)
        local output_filename = os.tmpname()
        local error_filename = os.tmpname()
        local shell_command =
          get_execute_command(command, output_filename, error_filename)
        local _, result_type_code, result_code =
          os.execute(shell_command)
        local Result = {}
        if (result_type_code == 'exit') then
          Result.is_aborted = false
        elseif (result_type_code == 'signal') then
          Result.is_aborted = true
        end
        Result.result_code = result_code
        Result.output = file_to_str(output_filename)
        Result.error = file_to_str(error_filename)
        os.remove(output_filename)
        os.remove(error_filename)
        local is_ok = (Result.result_code == 0)
        return is_ok, Result
      end
    return execute_shell_command
  end
_G.package.preload['workshop.concepts.shell.quote.SpecialChars'] =
  function(...)
    local SpaceChars = request('SpaceChars')
    local add_list = request('!.concepts.list.add_list')
    local SpecialChars =
      {
        '"',
        '$',
        '&',
        "'",
        '(',
        ')',
        '*',
        ';',
        '<',
        '>',
        '[',
        [[\]],
        ']',
        '^',
        '`',
        '{',
        '|',
        '}',
      }
    add_list(SpecialChars, SpaceChars)
    return SpecialChars
  end
_G.package.preload['workshop.concepts.shell.quote.SpaceChars'] =
  function(...)
    local SpaceChars = { '\009', '\010', ' ' }
    return SpaceChars
  end
_G.package.preload['workshop.concepts.list.to_string'] =
  function(...)
    local to_string =
      function(List, separator_str)
        assert_table(List)
        separator_str = separator_str or ''
        assert_string(separator_str)
        return table.concat(List, separator_str)
      end
    return to_string
  end
_G.package.preload['workshop.concepts.list.add_item'] =
  function(...)
    local add_item =
      function(OurList, item)
        table.insert(OurList, item)
      end
    return add_item
  end
_G.package.preload['workshop.concepts.list.add_list'] =
  function(...)
    local add_list =
      function(OurList, AnotherList)
        table.move(AnotherList, 1, #AnotherList, #OurList + 1, OurList)
      end
    return add_list
  end
_G.package.preload['workshop.concepts.words.to_string'] =
  function(...)
    local list_to_string = request('!.concepts.list.to_string')
    local to_string =
      function(Words)
        return list_to_string(Words, ' ')
      end
    return to_string
  end
_G.package.preload[
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
_G.package.preload[
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
_G.package.preload[
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
_G.package.preload[
  'workshop.concepts.lua_bytecode_decompiler.listing_from_bytecode.parse_listing'
] =
  function(...)
    local cleanup_spaces
    do
      local str_gsub = string.gsub
      local str_trim = request('!.string.trim')
      cleanup_spaces =
        function(str)
          str = str_gsub(str, '\t', ' ')
          str = str_gsub(str, '  +', ' ')
          str = str_trim(str)
          return str
        end
    end
    local str_split
    do
      local base_str_split = request('!.string.split')
      str_split =
        function(str)
          return base_str_split(str, ' ')
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
              local comment_pos = str_find(opcode_line, ';')
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
_G.package.preload[
  'workshop.concepts.lua_bytecode_decompiler.listing_from_bytecode.get_listing'
] =
  function(...)
    local file_from_str = request('!.convert.file_from_str')
    local get_cmd_decompile =
      request('!.mechs.cmdline.get_cmd_decompile_lua_bytecode')
    local run_shell_command = request('!.concepts.shell.execute')
    local rmfile = request('!.file_system.file.remove')
    local get_listing =
      function(bytecode_str)
        local output_str
        local bytecode_file_name = os.tmpname()
        file_from_str(bytecode_str, bytecode_file_name)
        local shell_command = get_cmd_decompile(bytecode_file_name)
        local is_ok, Results = run_shell_command(shell_command)
        output_str = Results.output
        rmfile(bytecode_file_name)
        return output_str
      end
    return get_listing
  end
_G.package.preload['workshop.concepts.StreamIo.Input.String'] =
  function(...)
    local is_natural = request('!.number.is_natural')
    local Interface =
      {
        Read =
          function(Me, num_bytes)
            assert(is_natural(num_bytes))
            local start_pos = Me.read_pos
            local end_pos =
              math.min(start_pos + num_bytes - 1, Me.data_len)
            Me.read_pos = end_pos + 1
            return string.sub(Me.data_str, start_pos, end_pos)
          end,
        Init =
          function(Me, arg_data_str)
            assert_string(arg_data_str)
            Me.data_str = arg_data_str
            Me.data_len = string.len(Me.data_str)
            Me.read_pos = 1
          end,
        data_str = '',
        data_len = 0,
        read_pos = 1,
      }
    return Interface
  end
_G.package.preload['workshop.concepts.StreamIo.Input.Lines'] =
  function(...)
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
        local newline = '\010'
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
_G.package.preload['workshop.concepts.StreamIo.Output.File'] =
  function(...)
    local open_file_for_writing =
      request('!.file_system.file.open_for_writing')
    local close_file = request('!.file_system.file.close')
    local Interface =
      {
        Write =
          function(Me, data_str)
            assert_string(data_str)
            assert(data_str ~= '')
            Me.File:write(data_str)
          end,
        Open =
          function(Me, pathname)
            local File = open_file_for_writing(pathname)
            if is_nil(File) then
              return false
            end
            Me.File = File
            return true
          end,
        Close =
          function(Me)
            close_file(Me.File)
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
_G.package.preload['workshop.concepts.path_name.pathname_to_str'] =
  function(...)
    local list_to_str = request('!.concepts.list.to_string')
    local names_sep = '/'
    local pathname_to_str =
      function(Pathname)
        return list_to_str(Pathname, names_sep)
      end
    return pathname_to_str
  end
_G.package.preload['workshop.concepts.path_name.pathname_from_str'] =
  function(...)
    local split_string = request('!.string.split')
    local sep = '/'
    local empty = ''
    local self_dir = '.'
    local upper_dir = '..'
    local pathname_from_str =
      function(path_name)
        assert_string(path_name)
        if (path_name == '') then
          error('Empty pathname.')
        end
        path_name = path_name .. sep
        local Path = split_string(path_name, sep)
        do
          local index = 2
          local current_item
          while (index <= #Path - 1) do
            current_item = Path[index]
            if
              (current_item == empty) or (current_item == self_dir)
            then
              table.remove(Path, index)
            else
              index = index + 1
            end
          end
        end
        setmetatable(
          Path,
          {
            __index =
              function(table, key)
                if (key == 'first_node') then
                  return table[1]
                elseif (key == 'last_node') then
                  return table[#table]
                end
              end,
          }
        )
        if (Path.first_node == self_dir) and (#Path >= 3) then
          table.remove(Path, 1)
        end
        if (Path.last_node == self_dir) and (#Path >= 2) then
          Path[#Path] = ''
        end
        local is_directory =
          (Path.last_node == self_dir) or
          (Path.last_node == upper_dir) or
          (Path.last_node == empty)
        if
          is_directory and ((Path.last_node ~= empty) or (#Path == 1))
        then
          table.insert(Path, '')
        end
        return Path
      end
    return pathname_from_str
  end
_G.package.preload['workshop.concepts.path_name.normalize'] =
  function(...)
    local pathname_from_str = request('pathname_from_str')
    local pathname_to_str = request('pathname_to_str')
    local normalize_name =
      function(path_name)
        return pathname_to_str(pathname_from_str(path_name))
      end
    return normalize_name
  end
_G.package.preload['callgraph.FlowOpcodes'] =
  function(...)
    local FlowOpcodes =
      {
        return_nothing = 'RETURN0',
        return_item = 'RETURN1',
        return_sequence = 'RETURN',
        jump = 'JMP',
        equal_reg = 'EQ',
        equal_const_table = 'EQK',
        less_than = 'LT',
        less_or_equal = 'LE',
        equal_imm = 'EQI',
        less_than_imm = 'LTI',
        less_or_equal_imm = 'LEI',
        greater_than_imm = 'GTI',
        greater_or_equal_imm = 'GEI',
        set_false_and_skip = 'LFALSESKIP',
        if_neq_then_skip = 'TEST',
        if_neq_then_skip_else_set = 'TESTSET',
        check_numeric_loop = 'FORPREP',
        check_generic_loop = 'TFORPREP',
        numeric_loop_back = 'FORLOOP',
        generic_loop_back = 'TFORLOOP',
      }
    return FlowOpcodes
  end
_G.package.preload['callgraph.get_next_ones'] =
  function(...)
    local get_next_ones
    do
      local Terminators_Map
      local Jumpers_Map
      local ForwardJumpers_Map
      local Skippers_Map
      local SkippersAndForwardJumpers_Map
      local SkippersAndBackwardJumpers_Map
      do
        local Terminators
        local Jumpers
        local ForwardJumpers
        local Skippers
        local SkippersAndForwardJumpers
        local SkippersAndBackwardJumpers
        do
          local FlowOpcodes = request('FlowOpcodes')
          Terminators =
            {
              FlowOpcodes.return_nothing,
              FlowOpcodes.return_item,
              FlowOpcodes.return_sequence,
            }
          Jumpers = { FlowOpcodes.jump }
          ForwardJumpers = { FlowOpcodes.check_generic_loop }
          Skippers =
            {
              FlowOpcodes.equal_reg,
              FlowOpcodes.equal_const_table,
              FlowOpcodes.less_than,
              FlowOpcodes.less_or_equal,
              FlowOpcodes.equal_imm,
              FlowOpcodes.less_than_imm,
              FlowOpcodes.less_or_equal_imm,
              FlowOpcodes.greater_than_imm,
              FlowOpcodes.greater_or_equal_imm,
              FlowOpcodes.set_false_and_skip,
              FlowOpcodes.if_neq_then_skip,
              FlowOpcodes.if_neq_then_skip_else_set,
            }
          SkippersAndForwardJumpers = { FlowOpcodes.check_numeric_loop }
          SkippersAndBackwardJumpers =
            {
              FlowOpcodes.numeric_loop_back,
              FlowOpcodes.generic_loop_back,
            }
        end
        local map_values = request('!.table.map_values')
        Terminators_Map = map_values(Terminators)
        Jumpers_Map = map_values(Jumpers)
        ForwardJumpers_Map = map_values(ForwardJumpers)
        Skippers_Map = map_values(Skippers)
        SkippersAndForwardJumpers_Map =
          map_values(SkippersAndForwardJumpers)
        SkippersAndBackwardJumpers_Map =
          map_values(SkippersAndBackwardJumpers)
      end
      local add_to_list = request('!.concepts.list.add_item')
      get_next_ones =
        function(instruction_index, Instruction)
          local NextOnes = {}
          local opcode = Instruction[1]
          local next_instruction_index = instruction_index + 1
          if Terminators_Map[opcode] then
            ;
          elseif Jumpers_Map[opcode] then
            local jump_offset = tonumber(Instruction[2])
            add_to_list(NextOnes, next_instruction_index + jump_offset)
          elseif ForwardJumpers_Map[opcode] then
            local jump_offset = tonumber(Instruction[3])
            add_to_list(NextOnes, next_instruction_index + jump_offset)
          elseif Skippers_Map[opcode] then
            add_to_list(NextOnes, next_instruction_index)
            add_to_list(NextOnes, next_instruction_index + 1)
          elseif SkippersAndForwardJumpers_Map[opcode] then
            local jump_offset = tonumber(Instruction[3])
            add_to_list(NextOnes, next_instruction_index)
            add_to_list(NextOnes, next_instruction_index + jump_offset)
          elseif SkippersAndBackwardJumpers_Map[opcode] then
            local jump_offset = tonumber(Instruction[3])
            add_to_list(NextOnes, next_instruction_index)
            add_to_list(NextOnes, next_instruction_index - jump_offset)
          else
            add_to_list(NextOnes, next_instruction_index)
          end
          return NextOnes
        end
    end
    return get_next_ones
  end
_G.package.preload['callgraph.callgraph_to_tgf'] =
  function(...)
    local callgraph_to_tgf
    do
      local OutputStream
      local write =
        function(str)
          OutputStream:Write(str)
        end
      local space = ' '
      local newline = '\010'
      local parts_delim = '#'
      local write_label =
        function(name, label)
          write(name)
          write(space)
          write(label)
          write(newline)
        end
      local write_sections_delimiter =
        function()
          write(newline)
          write(parts_delim)
          write(newline)
          write(newline)
        end
      local write_link =
        function(src_name, dest_name)
          write(src_name)
          write(space)
          write(dest_name)
          write(newline)
        end
      local set_node_name_format
      local get_node_name
      do
        local node_name_format
        do
          local get_num_digits = request('!.number.get_num_dec_digits')
          local int_to_str = tostring
          set_node_name_format =
            function(num_instructions)
              local num_digits = get_num_digits(num_instructions)
              node_name_format = '%0' .. int_to_str(num_digits) .. 'd'
            end
        end
        do
          local str_format = string.format
          get_node_name =
            function(index)
              return str_format(node_name_format, index)
            end
        end
      end
      callgraph_to_tgf =
        function(InstructionsGraph, Arg_OutputStream)
          OutputStream = Arg_OutputStream
          do
            local num_instructions = #InstructionsGraph
            set_node_name_format(num_instructions)
          end
          for
            instruction_index, Instruction in ipairs(InstructionsGraph)
          do
            local name = get_node_name(instruction_index)
            write_label(name, Instruction.label)
          end
          write_sections_delimiter()
          for
            src_instruction_index, Instruction in
              ipairs(InstructionsGraph)
          do
            local NextOnes = Instruction.NextOnes
            local is_branch_node = (#NextOnes > 1)
            if is_branch_node then
              write(newline)
            end
            for _, dest_instruction_index in ipairs(NextOnes) do
              local src_name = get_node_name(src_instruction_index)
              local dest_name = get_node_name(dest_instruction_index)
              write_link(src_name, dest_name)
            end
            if is_branch_node then
              write(newline)
            end
          end
        end
    end
    return callgraph_to_tgf
  end
_G.package.preload['callgraph.callgraph_to_dot'] =
  function(...)
    local callgraph_to_dot
    do
      local OutputStream
      local write =
        function(str)
          OutputStream:Write(str)
        end
      local space = ' '
      local newline = '\010'
      local quote = '"'
      local semicol = ';'
      local equal = '='
      local opening_brace = '{'
      local closing_brace = '}'
      local opening_bracket = '['
      local closing_bracket = ']'
      local arrow = '->'
      local kw_digraph = 'digraph'
      local kw_label = 'label'
      local start_graph =
        function(graph_name)
          write(kw_digraph)
          write(space)
          write(graph_name)
          write(newline)
          write(opening_brace)
          write(newline)
        end
      local end_graph =
        function()
          write(closing_brace)
          write(newline)
        end
      local set_node_name_format
      local get_node_name
      do
        local node_name_format
        do
          local get_num_digits = request('!.number.get_num_dec_digits')
          local int_to_str = tostring
          set_node_name_format =
            function(num_instructions)
              local num_digits = get_num_digits(num_instructions)
              node_name_format =
                quote .. '%0' .. int_to_str(num_digits) .. 'd' .. quote
            end
        end
        do
          local str_format = string.format
          get_node_name =
            function(index)
              return str_format(node_name_format, index)
            end
        end
      end
      local indent = '  '
      local write_label =
        function(name, label)
          write(indent)
          write(name)
          write(space)
          write(opening_bracket)
          write(space)
          write(kw_label)
          write(space)
          write(equal)
          write(space)
          write(quote)
          write(label)
          write(quote)
          write(space)
          write(closing_bracket)
          write(semicol)
          write(newline)
        end
      local write_link =
        function(src_name, dest_name)
          write(indent)
          write(src_name)
          write(space)
          write(arrow)
          write(space)
          write(dest_name)
          write(semicol)
          write(newline)
        end
      callgraph_to_dot =
        function(InstructionsGraph, graph_name, Arg_OutputStream)
          OutputStream = Arg_OutputStream
          do
            local num_instructions = #InstructionsGraph
            set_node_name_format(num_instructions)
          end
          start_graph(graph_name)
          for
            instruction_index, Instruction in ipairs(InstructionsGraph)
          do
            local name = get_node_name(instruction_index)
            write_label(name, Instruction.label)
          end
          write(newline)
          for
            src_instruction_index, Instruction in
              ipairs(InstructionsGraph)
          do
            local NextOnes = Instruction.NextOnes
            local is_branch_node = (#NextOnes > 1)
            if is_branch_node then
              write(newline)
            end
            for _, dest_instruction_index in ipairs(NextOnes) do
              local src_name = get_node_name(src_instruction_index)
              local dest_name = get_node_name(dest_instruction_index)
              write_link(src_name, dest_name)
            end
            if is_branch_node then
              write(newline)
            end
          end
          end_graph()
        end
    end
    return callgraph_to_dot
  end
return require('run')