## What

Early prototype.

Generates call graphs for Lua 5.5 bytecode.

Graphs are stored as files inside `output/` directory.
Graphs are generated in two formats: `.tgf` (trivial graph format)
and in `.dot` (graph format for `Graphviz` package)

`.tgf` can be loaded into `yEd` graph editor and manually processed.
`.dot` can be converted to `.svg` with supplied shell script.

![Part of generated image][lua_callgraph_img]

## Usage

```
$ lua run.lua

Creates call graphs for Lua code.

Usage: <lua_file_name>

Writes results to ./output/ .

-- Martin, 2026-07
```

## Requirements

  * Linux
  * Lua 5.5 (not tested yet on 5.3 and 5.4)
  * Graphviz package for `dot` program

## Install/remove

  * Clone repo

[lua_callgraph_img]: images/Callgraph-Sample.png
