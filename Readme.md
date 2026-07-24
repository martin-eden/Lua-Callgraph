[![DeepWiki][DeepWiki_Logo]][DeepWiki_Repo] (will answer your questions)

## What

| Created | Updated | Code size | License |
|:-------:|:-------:|:---------:|:-------:|
| 2026-07 | 2026-07 |  < 80 K   |  LGPL3  |

Generates call graphs for any valid Lua 5.5 source code.

Graphs are generated in two formats: `.tgf` (trivial graph format)
and in `.dot` (graph format for [`Graphviz`][Graphviz] package)

`.tgf` can be loaded into [`yEd`][yEd] graph editor and manually processed.
`.dot` can be converted to `.svg` with supplied shell script.

![Part of generated image][lua_callgraph_img]


## Shipment

Repository contains

  * Compiled code in [`deploy/`][deploy]
  * Complete source code in [`src/`][src]
  * Rebuild script and tools in [`builder/`](builder/)
  * Sample code in [`samples/test.lua`](samples/test.lua)
  * Sample output in [`output/`](output/)


## Requirements

  * Linux
  * Lua 5.5 (not tested yet on 5.3 and 5.4)
  * `graphviz` package for `dot` program


## Typical usage

Save two files from [`deploy/`][deploy]:

  * [generate_callgraphs_lua.lua][compiled_tool] creates graphs
    descriptions in two text formats:

    ```
    $ lua generate_callgraphs_lua.lua

    Creates call graphs for Lua code.

    Usage: <lua_file_name> <output_dir>

    -- Martin, 2026-07
    ```
  * [layout_callgraphs.sh][layout_script] calls `dot` tool to
    layout graphs and save them as `.svg` images:

    ```
    $ ./layout_callgraphs.sh
    For given Lua source file creates .svg callgraphs in <output_dir>/svg

    Usage: lua_source_file output_dir

    ```

## Modification

Modify files in [`src/`][src].


## Rebuilding

  * Clone [`workshop`][workshop] repo
  * Checkout it near current date, `2026-07-24`
  * Modify `package.path` in [`builder/create_deploy.lua`][create_deploy]
    so that it finds your cloned `workshop`
  * Run [`builder/rebuild.sh`][rebuild]


## See also

  * [`workshop`][workshop] -- my personal framework
  * [`contents`][contents] -- my other projects

[DeepWiki_Logo]: https://deepwiki.com/badge.svg
[DeepWiki_Repo]: https://deepwiki.com/martin-eden/Lua-Callgraph

[lua_callgraph_img]: images/Callgraph-Sample.png
[yEd]: https://www.yworks.com/products/yed
[Graphviz]: https://graphviz.org/download/
[src]: src/
[deploy]: deploy/
[compiled_tool]: deploy/generate_callgraphs_lua.lua
[layout_script]: deploy/layout_callgraphs.sh
[create_deploy]: builder/create_deploy.lua
[rebuild]: builder/rebuild.sh
[workshop]: https://github.com/martin-eden/workshop
[contents]: https://github.com/martin-eden/contents
