#!/bin/sh

# Pack program into one Lua code file

#
# Author: Martin Eden
# Last mod.: 2026-07-17
#

#
# Results are placed in "deploy/"
#
# Toolchain uses my "lua code melder" tool to combine files into one:
#
#   https://github.com/martin-eden/lua_code_melder
#
# Toolchain uses my "lua code formatter" tool to strip comments:
#
#   https://github.com/martin-eden/lua_code_formatter
#

set -e -u

#
# src/
#

cd ../src

# ( Get dependencies from [workshop]
rm -r -f workshop/

lua ../builder/create_deploy.lua

bash deploy.sh
rm deploy.sh

mv deploy/workshop/ .
rm -r -f deploy/
# )

cp layout_callgraphs.sh ../deploy/

#
# builder/
#

cd ../builder

# ( Combine all Lua code, reformat and strip comments
./meld ../src/ generate_callgraphs_lua > ../deploy/generate_callgraphs_lua.melded.lua

./reformat_lua \
  ../deploy/generate_callgraphs_lua.melded.lua \
  ../deploy/generate_callgraphs_lua.melded.stripped.lua \
  --~keep-comments \
  --right-margin=72
rm ../deploy/generate_callgraphs_lua.melded.lua

mv \
  ../deploy/generate_callgraphs_lua.melded.stripped.lua \
  ../deploy/generate_callgraphs_lua.lua
# )

#
# deploy/
#

cd ../deploy

# Do test run
./layout_callgraphs.sh ../samples/test.lua ../output

# 2026 # # # #
# 2026-07-17
