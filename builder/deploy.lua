-- Load modules, get list of all required Lua files, copy them

--[[
  Author: Martin Eden
  Last mod.: 2026-10-19
]]

--[[
  How to use

  * Include root modules in <ModulesList>

  * Do one of

    * Copy this file to root Lua source directory

    * Call this file from Lua source directory:

        $ lua ../builder/create_deploy.lua

  Make sure that main Lua file executes without errors when
  loaded as module. If needed, make changes to it to behave so.
]]

--
local Modules = { 'generate_callgraphs_lua' }
--
package.path = package.path .. ';../../../?.lua'
--
local ModulePaths, Deps
do
  arg[1] = '../samples/test.lua'
  arg[2] = '../output/'
  local observe_modules = require('workshop.system.observe_modules')
  ModulePaths, Deps = observe_modules(Modules)
end
--
require('workshop.base')

local FilesList
do
  local add_to = request('!.concepts.list.add_item')
  FilesList = { }
  for _, ModuleLoc in ipairs(ModulePaths) do
    add_to(FilesList, ModuleLoc[2])
  end
end

local deploy = request('!.mechs.deploy')

deploy(FilesList)
--

--[=[ Depencencies observation block for meat
do
  local Graph
  do
    local deps_to_graph = request('!.mechs.deps_to_graph')
    Graph = deps_to_graph(Deps, OutputStream)
  end
  local output_file_name = '../deps/dependencies.tgf'
  local OutputStream
  do
    local OutputFile = request('!.concepts.StreamIo.Output.File')
    OutputStream = OutputFile.create(output_file_name)
  end
  local write_graph = request('!.concepts.coder_tgf.compile')
  OutputStream:Open()
  write_graph(Graph, OutputStream)
  OutputStream:Close()
  --[[
  do
    local svg_file_name = '../deps/dependencies.svg'
    local get_cmd_dot_to_svg = request('!.mechs.cmdline.get_cmd_dot_to_svg')
    get_cmd_dot_to_svg(dot_file_name, svg_file_name):Execute()
  end
  --]]
end
--]=]

--[[
  202?
  2026 # # # #
  2026-09-24
]]
