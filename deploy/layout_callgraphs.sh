#!/bin/bash

# For given Lua source file create .svg callgraphs in ./output/svg/

# Author: Martin Eden
# Last mod.: 2026-07-23

print_help() {
  cat <<'EOF'
For given Lua source file creates .svg callgraphs in <output_dir>/svg

Usage: lua_source_file output_dir

EOF
}

if test -z "$2"; then
  print_help
  exit 1
fi

set -e -u

pathname="$1"
base_dir="$2"

rm -r -f "$base_dir"/*

#
# Create callgraphs
#
# It creates *.dot and *.tgf files in "$base_dir/dot" and "$base_dir/tgf".
#
lua generate_callgraphs_lua.lua "$pathname" "$base_dir"

#
# Layout to SVG
#
# Create "$base_dir/svg" and call GraphViz to convert data
#
dot_dir="$base_dir"/dot
svg_dir="$base_dir"/svg

mkdir "$svg_dir"

for pathname in "$dot_dir"/*; do
  dot_file_name="$(basename $pathname)"
  svg_file_name="${dot_file_name%.*}.svg"

  dot -Tsvg "$pathname" -o "$svg_dir/$svg_file_name"
done

# 2026-07-17
# 2026-07-23
