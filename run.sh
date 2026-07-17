#!/bin/bash

# For given Lua source file create .svg callgraphs in ./output/

# Author: Martin Eden
# Last mod.: 2026-07-17

print_help() {
  cat <<'EOF'
For given Lua source file creates .svg callgraphs in ./output/

Usage: lua_source_file

EOF
}

pathname="$1"

if test -z "$1"; then
  print_help
  exit 1
fi

dir='output'

rm -f "$dir"/*

lua run.lua "$pathname"

# Convert GraphViz data to SVG
for pathname in "$dir"/*.dot; do
  dot_file_name="$(basename "$pathname")"
  svg_file_name="${dot_file_name%.*}".svg

  dot -Tsvg "$dir/$dot_file_name" -o "$dir/$svg_file_name"
done

# 2026-07-17
