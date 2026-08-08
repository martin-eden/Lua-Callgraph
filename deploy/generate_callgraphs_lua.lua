_G.package.preload['generate_callgraphs_lua'] =
  function(...)
    require('workshop.base')
    local AsciiChars = request('!.concepts.Ascii.Chars')
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
        function(source_code_path_name)
          return
            get_listing(
              get_bytecode(file_to_str(source_code_path_name))
            )
        end
    end
    local get_callgraph
    do
      local space = AsciiChars.space
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
          function(Callgraph, graph_name, file_name)
            local OutputStream = new(OutputFileStream)
            OutputStream:Open(file_name)
            callgraph_to_dot(Callgraph, graph_name, OutputStream)
            OutputStream:Close()
          end
      end
    end
    local usage_text =
      [[
Creates VM instruction call graphs for Lua code

Usage: <lua_file_name> <output_dir>

-- Martin, 2026-07
]]
    local Config =
      { source_code_path_name = arg[1], output_dir_name = arg[2] }
    local console_write =
      function(str)
        io.stdout:write(str)
      end
    local console_print
    do
      local newline = AsciiChars.newline
      console_print =
        function(str)
          console_write(str)
          console_write(newline)
        end
    end
    do
      local NamesGiver
      NamesGiver = request('NamesGiver.Interface')
      NamesGiver = NamesGiver.create()
      local Chunks
      do
        local source_code_path_name = Config.source_code_path_name
        local output_dir_name = Config.output_dir_name
        if not (source_code_path_name and output_dir_name) then
          console_write(usage_text)
          return
        end
        console_print('( Generating callgraphs')
        NamesGiver:SetSourceName(source_code_path_name)
        NamesGiver:SetOutputDir(output_dir_name)
        do
          local remove_dir = request('!.file_system.directory.remove')
          local create_dir = request('!.file_system.directory.create')
          do
            local tgf_dir = NamesGiver:GetTgfDir()
            remove_dir(tgf_dir)
            create_dir(tgf_dir)
          end
          do
            local dot_dir = NamesGiver:GetDotDir()
            remove_dir(dot_dir)
            create_dir(dot_dir)
          end
        end
        Chunks = get_chunks(source_code_path_name)
      end
      NamesGiver:SetNumItems(#Chunks)
      for chunk_index, Chunk in ipairs(Chunks) do
        local Callgraph = get_callgraph(Chunk)
        do
          local file_name = NamesGiver:GetTgfPathname(chunk_index)
          export_to_tgf(Callgraph, file_name)
        end
        do
          local graph_name = NamesGiver:GetDotGraphname(chunk_index)
          local file_name = NamesGiver:GetDotPathname(chunk_index)
          export_to_dot(Callgraph, graph_name, file_name)
        end
      end
      console_print(')')
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
_G.package.preload['workshop.mechs.cmdline.get_cmd_mkdir'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local quote = request('!.concepts.shell.quote')
    local glue_words = request('!.concepts.words.to_string')
    return
      function(dir_name)
        local Command = { 'mkdir', '-p', quote(normalize(dir_name)) }
        return glue_words(Command)
      end
  end
_G.package.preload['workshop.mechs.cmdline.get_cmd_rmdir'] =
  function(...)
    local normalize = request('!.concepts.path_name.normalize')
    local quote = request('!.concepts.shell.quote')
    local glue_words = request('!.concepts.words.to_string')
    return
      function(dir_name)
        local Command = { 'rm', '-r', '-f', quote(normalize(dir_name)) }
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
_G.package.preload['workshop.table.create_instance'] =
  function(...)
    local clone = request('clone')
    local attach_methods = request('attach_methods')
    local create_instance =
      function(Data, Methods)
        assert_table(Data)
        assert_table(Methods)
        local Result
        Result = clone(Data)
        attach_methods(Result, Methods)
        return Result
      end
    return create_instance
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
_G.package.preload['workshop.table.attach_methods'] =
  function(...)
    local attach_methods =
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
    return attach_methods
  end
_G.package.preload['workshop.file_system.directory.create'] =
  function(...)
    local directory_exists = request('exists')
    local get_mkdir_command = request('!.mechs.cmdline.get_cmd_mkdir')
    local shell_execute = request('!.concepts.shell.execute')
    local create_dir =
      function(dir_name)
        assert_string(dir_name)
        if directory_exists(dir_name) then
          return true
        end
        local mkdir_cmd = get_mkdir_command(dir_name)
        shell_execute(mkdir_cmd)
        if directory_exists(dir_name) then
          return true
        end
        return false
      end
    return create_dir
  end
_G.package.preload['workshop.file_system.directory.exists'] =
  function(...)
    local normalize_name = request('!.concepts.path_name.normalize')
    local is_directory =
      function(dir_name)
        assert_string(dir_name)
        dir_name = normalize_name(dir_name)
        local file = io.open(dir_name, 'rb')
        if is_nil(file) then
          return false
        end
        local _, err_str, err_num = file:read(1)
        local is_dir = (err_num == 21) and (err_str == 'Is a directory')
        file:close()
        return is_dir
      end
    return is_directory
  end
_G.package.preload['workshop.file_system.directory.remove'] =
  function(...)
    local directory_exists = request('exists')
    local get_rmdir_command = request('!.mechs.cmdline.get_cmd_rmdir')
    local shell_execute = request('!.concepts.shell.execute')
    local delete_dir =
      function(dir_name)
        assert_string(dir_name)
        if not directory_exists(dir_name) then
          return true
        end
        local rmdir_cmd = get_rmdir_command(dir_name)
        shell_execute(rmdir_cmd)
        if not directory_exists(dir_name) then
          return true
        end
        return false
      end
    return delete_dir
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
_G.package.preload['workshop.concepts.PaddedIndex'] =
  function(...)
    local is_natural = request('!.number.is_natural')
    local get_max_index =
      function(Me)
        return Me[1]
      end
    local get_format =
      function(Me)
        return Me[2]
      end
    local to_string =
      function(Me, index)
        assert(is_natural(index))
        assert(index <= get_max_index(Me))
        local str_format = string.format
        return str_format(get_format(Me), index)
      end
    local Interface
    Interface =
      {
        ToString = to_string,
        create =
          function(max_index)
            assert(is_natural(max_index))
            local zeroes_padding_format
            do
              local get_num_dec_digits =
                request('!.number.get_num_dec_digits')
              local int_to_str = tostring
              local num_digits = get_num_dec_digits(max_index)
              zeroes_padding_format =
                '%0' .. int_to_str(num_digits) .. 'd'
            end
            local create_instance = request('!.table.create_instance')
            local Core = { max_index, zeroes_padding_format }
            return create_instance(Core, Interface)
          end,
      }
    return Interface
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
    local AsciiChars = request('!.concepts.Ascii.Chars')
    local SpaceChars =
      { AsciiChars.tab, AsciiChars.newline, AsciiChars.space }
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
_G.package.preload['workshop.concepts.Ascii.Chars'] =
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
_G.package.preload['workshop.concepts.Ascii.Codes'] =
  function(...)
    local Codes =
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
    return Codes
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
            assert(data_str ~= '')
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
_G.package.preload['workshop.concepts.path_name.is_directory'] =
  function(...)
    local empty = ''
    local self_dir = '.'
    local upper_dir = '..'
    local is_directory =
      function(Pathname)
        assert_table(Pathname)
        local last_node = Pathname[#Pathname]
        return
          (last_node == empty) or
          (last_node == self_dir) or
          (last_node == upper_dir)
      end
    return is_directory
  end
_G.package.preload['workshop.concepts.path_name.get_name'] =
  function(...)
    local is_directory = request('is_directory')
    local empty = ''
    local self_dir = '.'
    local get_name =
      function(Pathname)
        assert_table(Pathname)
        local leaf_name
        if is_directory(Pathname) then
          leaf_name = Pathname[#Pathname - 1]
        else
          leaf_name = Pathname[#Pathname]
        end
        if (leaf_name == empty) then
          leaf_name = self_dir
        end
        return leaf_name
      end
    return get_name
  end
_G.package.preload['workshop.concepts.path_name.add_dir_postfix'] =
  function(...)
    local ends_with = request('!.string.ends_with')
    local add_dir_postfix =
      function(str)
        local dir_sep = '/'
        if ends_with(str, dir_sep) then
          return str
        end
        return str .. dir_sep
      end
    return add_dir_postfix
  end
_G.package.preload['callgraph.get_next_ones'] =
  function(...)
    local get_next_ones
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
        get_next_ones = request('vm_2015.get_next_ones')
      elseif use_vm_2020 then
        get_next_ones = request('vm_2020.get_next_ones')
      end
    end
    return get_next_ones
  end
_G.package.preload['callgraph.callgraph_to_tgf'] =
  function(...)
    local AsciiChars = request('!.concepts.Ascii.Chars')
    local callgraph_to_tgf
    do
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
      callgraph_to_tgf =
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
              write_link(
                src_name, get_node_name(dest_instruction_index)
              )
            end
            if is_forking_node then
              write_empty_line()
            end
          end
        end
    end
    return callgraph_to_tgf
  end
_G.package.preload['callgraph.callgraph_to_dot'] =
  function(...)
    local DotSerializer = request('callgraph_to_dot.DotSerializer')
    local serialize_links
    do
      serialize_links =
        function(InstructionsGraph)
          local NumInLinks_Map = {}
          for instruction_index in ipairs(InstructionsGraph) do
            NumInLinks_Map[instruction_index] = 0
          end
          NumInLinks_Map[1] = 1
          for
            instruction_index, Instruction in ipairs(InstructionsGraph)
          do
            for _, next_one_index in ipairs(Instruction.NextOnes) do
              NumInLinks_Map[next_one_index] =
                NumInLinks_Map[next_one_index] + 1
            end
          end
          for
            instruction_index, Instruction in ipairs(InstructionsGraph)
          do
            if (NumInLinks_Map[instruction_index] > 1) then
              DotSerializer.done_write_links()
            end
            DotSerializer.write_links(
              instruction_index, Instruction.NextOnes
            )
          end
          DotSerializer.done_write_links()
        end
    end
    local callgraph_to_dot =
      function(InstructionsGraph, graph_name, OutputStream)
        DotSerializer =
          DotSerializer.create(#InstructionsGraph, OutputStream)
        DotSerializer.start_graph(graph_name)
        serialize_links(InstructionsGraph)
        DotSerializer.write_empty_line()
        for
          instruction_index, Instruction in ipairs(InstructionsGraph)
        do
          DotSerializer.write_node(instruction_index, Instruction.label)
        end
        DotSerializer.end_graph()
      end
    return callgraph_to_dot
  end
_G.package.preload['callgraph.vm_2020.FlowOpcodes'] =
  function(...)
    local FlowOpcodes =
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
    return FlowOpcodes
  end
_G.package.preload['callgraph.vm_2020.get_next_ones'] =
  function(...)
    local get_next_ones
    do
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
      get_next_ones =
        function(instruction_index, Instruction)
          local NextOnes = {}
          local opcode = Instruction[1]
          local next_instruction = instruction_index + 1
          if Terminators_Map[opcode] then
            ;
          elseif (opcode == opcode_lfalseskip) then
            add_to_list(NextOnes, next_instruction + 1)
          elseif (opcode == opcode_jmp) then
            add_to_list(
              NextOnes, next_instruction + tonumber(Instruction[2])
            )
          elseif (opcode == opcode_tforprep) then
            add_to_list(
              NextOnes, next_instruction + tonumber(Instruction[3])
            )
          elseif BasicForks_Map[opcode] then
            add_to_list(NextOnes, next_instruction)
            add_to_list(NextOnes, next_instruction + 1)
          elseif Loopbacks_Map[opcode] then
            add_to_list(
              NextOnes, next_instruction - tonumber(Instruction[3])
            )
            add_to_list(NextOnes, next_instruction)
          elseif (opcode == opcode_forprep) then
            add_to_list(NextOnes, next_instruction)
            add_to_list(
              NextOnes, next_instruction + tonumber(Instruction[3]) + 1
            )
          else
            add_to_list(NextOnes, next_instruction)
          end
          return NextOnes
        end
    end
    return get_next_ones
  end
_G.package.preload['callgraph.vm_2015.FlowOpcodes'] =
  function(...)
    local FlowOpcodes =
      {
        [1] = { 'TAILCALL', 'RETURN' },
        [2] = 'JMP',
        [3] = { 'EQ', 'LT', 'LE', 'TEST', 'TESTSET' },
        [4] = { 'FORLOOP', 'TFORLOOP' },
        [5] = 'FORPREP',
      }
    return FlowOpcodes
  end
_G.package.preload['callgraph.vm_2015.get_next_ones'] =
  function(...)
    local get_next_ones
    do
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
      get_next_ones =
        function(instruction_index, Instruction)
          local NextOnes = {}
          local opcode = Instruction[1]
          local next_instruction = instruction_index + 1
          if Terminators_Map[opcode] then
            ;
          elseif (opcode == opcode_jmp) then
            add_to_list(
              NextOnes, next_instruction + tonumber(Instruction[3])
            )
          elseif BasicForks_Map[opcode] then
            add_to_list(NextOnes, next_instruction)
            add_to_list(NextOnes, next_instruction + 1)
          elseif Loopbacks_Map[opcode] then
            add_to_list(
              NextOnes, next_instruction + tonumber(Instruction[3])
            )
            add_to_list(NextOnes, next_instruction)
          elseif (opcode == opcode_forprep) then
            add_to_list(
              NextOnes, next_instruction + tonumber(Instruction[3])
            )
          else
            add_to_list(NextOnes, next_instruction)
          end
          return NextOnes
        end
    end
    return get_next_ones
  end
_G.package.preload['callgraph.callgraph_to_dot.DotSerializer'] =
  function(...)
    local Methods
    local IndexSerializer
    local Writer
    local create
    do
      IndexSerializer = request('!.concepts.PaddedIndex')
      Writer = request('mechs.Writer')
      create =
        function(num_instructions, OutputStream)
          IndexSerializer = IndexSerializer.create(num_instructions)
          Writer.init(OutputStream)
          return Methods
        end
    end
    local get_node_name =
      function(index)
        return IndexSerializer:ToString(index)
      end
    local write_node =
      function(index, label)
        Writer.write_node(get_node_name(index), label)
      end
    local write_links
    do
      local add_to_list = request('!.concepts.list.add_item')
      write_links =
        function(index, NextOnes)
          local NextOneNames = {}
          for _, next_one_index in ipairs(NextOnes) do
            add_to_list(NextOneNames, get_node_name(next_one_index))
          end
          Writer.write_links(get_node_name(index), NextOneNames)
        end
    end
    Methods =
      {
        create = create,
        write_empty_line = Writer.write_empty_line,
        start_graph = Writer.start_graph,
        end_graph = Writer.end_graph,
        write_node = write_node,
        write_links = write_links,
        done_write_links = Writer.done_write_links,
      }
    return Methods
  end
_G.package.preload['callgraph.callgraph_to_dot.mechs.LinksWriter'] =
  function(...)
    local Syntels = request('^.concepts.Syntels')
    local Writer
    local write_subgraph
    do
      local start_graph = Syntels.start_graph
      local end_graph = Syntels.end_graph
      write_subgraph =
        function(DestNames)
          Writer.write_cont(start_graph)
          for _, dest_name in ipairs(DestNames) do
            Writer.write_cont(Writer.quote(dest_name))
          end
          Writer.write(end_graph)
          Writer.end_statement()
        end
    end
    local Queue = { [1] = false, [2] = false }
    local queue_add =
      function(name)
        if Queue[1] then
          Writer.write_cont(Queue[1])
          Writer.write_arrow()
        end
        Queue[1], Queue[2] = Queue[2], name
      end
    local queue_flush =
      function()
        if Queue[1] then
          Writer.write_cont(Queue[1])
          Writer.write_arrow()
          Writer.write(Queue[2])
          Writer.end_statement()
        end
        Queue[1], Queue[2] = false, false
      end
    local write_links =
      function(source_name, DestNames)
        source_name = Writer.quote(source_name)
        if (#DestNames == 0) then
          queue_flush()
        elseif (#DestNames == 1) then
          local dest_name = Writer.quote(DestNames[1])
          if (source_name == Queue[2]) then
            queue_add(dest_name)
          else
            queue_flush()
            Writer.start_statement()
            queue_add(source_name)
            queue_add(dest_name)
          end
        else
          if (source_name == Queue[2]) then
            Writer.write_cont(Queue[1])
            Writer.write_arrow()
            Writer.write_cont(Queue[2])
            Writer.write_arrow()
            Queue[1], Queue[2] = false, false
            write_subgraph(DestNames)
          else
            queue_flush()
            Writer.start_statement()
            Writer.write_cont(source_name)
            Writer.write_arrow()
            write_subgraph(DestNames)
          end
        end
      end
    local Interface =
      {
        init =
          function(Arg_Writer)
            Writer = Arg_Writer
          end,
        write_links = write_links,
        done_write_links = queue_flush,
      }
    return Interface
  end
_G.package.preload['callgraph.callgraph_to_dot.mechs.Writer'] =
  function(...)
    local Syntels = request('^.concepts.Syntels')
    local Delimiters = request('concepts.Delimiters')
    local Spaces = request('^.concepts.Spaces')
    local LinksWriter = request('LinksWriter')
    local OutputStream
    local line_len = 0
    local write =
      function(str)
        if (str == '') then
          return
        end
        OutputStream:Write(str)
        line_len = line_len + #str
      end
    local write_cont
    do
      local line_item_separator = Delimiters.line_item_separator
      write_cont =
        function(str)
          write(str)
          write(line_item_separator)
        end
    end
    local write_final
    do
      local line_separator = Delimiters.line_separator
      write_final =
        function(str)
          write(str)
          write(line_separator)
          line_len = 0
        end
    end
    local write_empty_line =
      function()
        write_final('')
      end
    local write_indent
    do
      local space = Spaces.space
      local indent = space .. space .. space
      write_indent =
        function()
          write(indent)
        end
    end
    local quote
    do
      local quote_char = Syntels.quote
      quote =
        function(str)
          return quote_char .. str .. quote_char
        end
    end
    local start_statement =
      function()
        write_indent()
      end
    local end_statement
    do
      local end_statement_str = Syntels.end_statement
      end_statement =
        function()
          write_final(end_statement_str)
        end
    end
    local start_attr
    do
      local start_attr_str = Syntels.start_attr
      start_attr =
        function()
          write_cont(start_attr_str)
        end
    end
    local end_attr
    do
      local end_attr_str = Syntels.end_attr
      end_attr =
        function()
          write(end_attr_str)
        end
    end
    local write_arrow
    do
      local wrapping_len = 45
      local arrow = Syntels.arrow
      write_arrow =
        function()
          if (line_len > wrapping_len) then
            write_final(arrow)
            write_indent()
            write_indent()
          else
            write_cont(arrow)
          end
        end
    end
    local write_label
    do
      local label_kw = Syntels.kw_label
      local assign = Syntels.assign
      write_label =
        function(label)
          start_attr()
          write_cont(label_kw)
          write_cont(assign)
          write_cont(label)
          end_attr()
        end
    end
    local start_graph
    do
      local strict = Syntels.kw_strict
      local digraph = Syntels.kw_digraph
      local start_graph_str = Syntels.start_graph
      start_graph =
        function(graph_name)
          write_cont(strict)
          write_cont(digraph)
          write_final(quote(graph_name))
          write_final(start_graph_str)
        end
    end
    local end_graph
    do
      local end_graph_str = Syntels.end_graph
      end_graph =
        function()
          write_final(end_graph_str)
        end
    end
    local write_node =
      function(name, label)
        start_statement()
        write_cont(quote(name))
        write_label(quote(label))
        end_statement()
      end
    local Methods
    Methods =
      {
        init =
          function(Arg_OutputStream)
            OutputStream = Arg_OutputStream
            LinksWriter.init(Methods)
          end,
        write = write,
        write_cont = write_cont,
        write_final = write_final,
        write_empty_line = write_empty_line,
        quote = quote,
        start_statement = start_statement,
        end_statement = end_statement,
        start_attr = start_attr,
        end_attr = end_attr,
        write_arrow = write_arrow,
        write_label = write_label,
        start_graph = start_graph,
        end_graph = end_graph,
        write_node = write_node,
        write_links = LinksWriter.write_links,
        done_write_links = LinksWriter.done_write_links,
      }
    return Methods
  end
_G.package.preload[
  'callgraph.callgraph_to_dot.mechs.concepts.Delimiters'
] =
  function(...)
    local Spaces = request('^.^.concepts.Spaces')
    local Delimiters =
      {
        line_item_separator = Spaces.space,
        line_separator = Spaces.newline,
      }
    return Delimiters
  end
_G.package.preload['callgraph.callgraph_to_dot.concepts.Spaces'] =
  function(...)
    local AsciiChars = request('!.concepts.Ascii.Chars')
    local Spaces =
      {
        space = AsciiChars.space,
        tab = AsciiChars.tab,
        newline = AsciiChars.newline,
      }
    return Spaces
  end
_G.package.preload['callgraph.callgraph_to_dot.concepts.Syntels'] =
  function(...)
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
    return Syntels
  end
_G.package.preload['NamesGiver.get_padded_number_format'] =
  function(...)
    local get_num_digits = request('!.number.get_num_dec_digits')
    local int_to_str = tostring
    local get_padded_number_format =
      function(num_items)
        local num_digits = get_num_digits(num_items)
        return '%0' .. int_to_str(num_digits) .. 'd'
      end
    return get_padded_number_format
  end
_G.package.preload['NamesGiver.get_file_name'] =
  function(...)
    local get_path_from_str =
      request('!.concepts.path_name.pathname_from_str')
    local get_name_from_path = request('!.concepts.path_name.get_name')
    local get_file_name =
      function(source_code_path_name)
        return
          get_name_from_path(get_path_from_str(source_code_path_name))
      end
    return get_file_name
  end
_G.package.preload['NamesGiver.get_base_dir'] =
  function(...)
    local add_dir_postfix =
      request('!.concepts.path_name.add_dir_postfix')
    local normalize_pathname = request('!.concepts.path_name.normalize')
    local get_base_dir =
      function(output_dir_name)
        return normalize_pathname(add_dir_postfix(output_dir_name))
      end
    return get_base_dir
  end
_G.package.preload['NamesGiver.Interface'] =
  function(...)
    local create_instance = request('!.table.create_instance')
    local set_output_dir
    do
      local get_base_dir = request('get_base_dir')
      set_output_dir =
        function(Me, output_dir_name)
          Me[1] = get_base_dir(output_dir_name)
        end
    end
    local get_output_dir =
      function(Me)
        return Me[1]
      end
    local set_source_name
    do
      local get_file_name = request('get_file_name')
      set_source_name =
        function(Me, source_file_name)
          Me[2] = get_file_name(source_file_name)
        end
    end
    local get_source_name =
      function(Me)
        return Me[2]
      end
    local set_num_items
    do
      local PaddedIndex = request('!.concepts.PaddedIndex')
      set_num_items =
        function(Me, num_items)
          Me[3] = PaddedIndex.create(num_items)
        end
    end
    local get_padded_index =
      function(Me, index)
        return Me[3]:ToString(index)
      end
    local get_tgf_dir
    local get_dot_dir
    local get_tgf_pathname
    local get_dot_pathname
    local get_dot_graphname
    do
      local str_tgf = 'tgf'
      local str_dot = 'dot'
      get_tgf_dir =
        function(Me)
          return get_output_dir(Me) .. str_tgf
        end
      get_dot_dir =
        function(Me)
          return get_output_dir(Me) .. str_dot
        end
      local slash
      local dot
      do
        local AsciiChars = request('!.concepts.Ascii.Chars')
        slash = AsciiChars.slash
        dot = AsciiChars.dot
      end
      get_tgf_pathname =
        function(Me, index)
          return
            get_tgf_dir(Me) ..
            slash ..
            get_source_name(Me) ..
            dot ..
            get_padded_index(Me, index) ..
            dot ..
            str_tgf
        end
      get_dot_pathname =
        function(Me, index)
          return
            get_dot_dir(Me) ..
            slash ..
            get_source_name(Me) ..
            dot ..
            get_padded_index(Me, index) ..
            dot ..
            str_dot
        end
      get_dot_graphname =
        function(Me, index)
          return
            get_source_name(Me) .. dot .. get_padded_index(Me, index)
        end
    end
    local Methods
    Methods =
      {
        create =
          function()
            local Core = { [1] = false, [2] = false, [3] = false }
            return create_instance(Core, Methods)
          end,
        SetOutputDir = set_output_dir,
        SetSourceName = set_source_name,
        SetNumItems = set_num_items,
        GetTgfDir = get_tgf_dir,
        GetDotDir = get_dot_dir,
        GetTgfPathname = get_tgf_pathname,
        GetDotPathname = get_dot_pathname,
        GetDotGraphname = get_dot_graphname,
      }
    return Methods
  end
return require('generate_callgraphs_lua')