#!/bin/sh

# Convert GraphViz data to SVG

# Author: Martin Eden
# Last mod.: 2026-07-15

dir='./output'

for pathname in "$dir"/*.dot; do
  if [ ! -f "$pathname" ]; then continue; fi

  dot_file_name="$(basename "$pathname")"
  file_path="$pathname"

  svg_file_name="${dot_file_name%.*}".svg

  dot -Tsvg "$dir/$dot_file_name" -o "$dir/$svg_file_name"
done

# 2026-07-15
