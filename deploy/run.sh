#!/bin/bash

# For given Lua source file create .svg callgraphs in ./output/svg/

# Author: Martin Eden
# Last mod.: 2026-07-17

set -e -u

print_help() {
  cat <<'EOF'
For given Lua source file creates .svg callgraphs in <output_dir>/svg

Usage: lua_source_file output_dir

EOF
}

pathname="$1"

if test -z "$1"; then
  print_help
  exit 1
fi

base_dir='output'

rm -r -f "$base_dir"/*

# Run callgraph generator. It creates *.dot and *.tgf files in "output/"
lua run.lua "$pathname" "$base_dir"

# Create file type subdirs in "output/" and toss generated files there
# (
tgf_dir="$base_dir"/tgf
dot_dir="$base_dir"/dot
svg_dir="$base_dir"/svg

mkdir "$tgf_dir"
mkdir "$dot_dir"
mkdir "$svg_dir"

mv "$base_dir"/*.tgf "$tgf_dir"
mv "$base_dir"/*.dot "$dot_dir"
# )

# Convert GraphViz data to SVG
for pathname in "$dot_dir"/*.dot; do
  dot_file_name="$(basename "$pathname")"
  svg_file_name="${dot_file_name%.*}".svg

  dot -Tsvg "$pathname" -o "$svg_dir/$svg_file_name"
done

# 2026-07-17
