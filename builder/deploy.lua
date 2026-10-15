-- Load modules, get list of all required Lua files, copy them

--[[
  Author: Martin Eden
  Last mod.: 2026-10-15
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

--[[ Depencencies observation block for meat
do
  local deps_to_dot = request('!.mechs.deps_to_graphviz')
  local OutputStream
  do
    local dot_file_name = 'dependencies.dot'
    local OutputFile = request('!.concepts.StreamIo.Output.File')
    OutputStream = OutputFile.create(dot_file_name)
  end
  OutputStream:Open()
  deps_to_dot(Deps, OutputStream)
  OutputStream:Close()
end
--]]

--[[
  202?
  2026 # # # #
  2026-09-24
]]
