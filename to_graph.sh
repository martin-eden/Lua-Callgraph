#!/bin/sh

# Convert GraphViz data to SVG

# Author: Martin Eden
# Last mod.: 2026-07-15

dot -Tsvg callgraph.dot -o callgraph_gv.svg
open callgraph_gv.svg

# 2026-07-15
