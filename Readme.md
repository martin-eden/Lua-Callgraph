[![DeepWiki][DeepWiki_Logo]][DeepWiki_Repo] (will answer your questions)

## What

| Created |  Updated   | Code size | License |
|:-------:|:----------:|:---------:|:-------:|
| 2026-07 | 2026-09-08 |   < 90 K  |  LGPL3  |

Generates control flow graphs for any valid Lua (5.3 5.4 5.5) source code.

## Workflow and details

We will place results in given directory.

We will use Lua compiler `luac` to get VM (virtual machine) instructions
from source code:

  * `.is` (Itness, strings tree)

    VM instructions listing. Human- and machine-friendly format.

We will create callgraphs in following formats:

  * `.tgf` (trivial graph format)

    Machine-friendly format. Graphs can be loaded by [`yEd`][yEd]
    graph editor and manually processed.

  * `.dot` (graph format of [`Graphviz`][Graphviz] program)

    Human-friendly format. Required to layout graphs to `.svg`.

We will use `dot` program from `graphviz` to layout graphs:

  * `.svg` (simple vector graphics)

    XML-based format for vector images. Used to display graphs to human.

![Part of generated image][lua_callgraph_img]


## Shipment

Repository contains

  * Compiled code in [`deploy/`][deploy]
  * Sample output in [`output/`](output/)
  * Sample input in [`samples/test.lua`](samples/test.lua)
  * Complete source code in [`src/`][src]
  * Rebuild script and tools in [`builder/`](builder/)


## Requirements

  * Linux
  * Lua 5.5 (or 5.4, 5.3) (`sudo apt install lua`)
  * `graphviz` package for `dot` program (`sudo apt install graphviz`)


## Typical usage

  * Save [`generate_callgraphs_lua.lua`][compiled_tool] from
    [`deploy/`][deploy]

  * Add it to your programs (f.e. place it in `~/bin/`)

  * Try it

    ```
    $ lua generate_callgraphs_lua.lua
    Creates VM instruction call graphs for Lua code

    Usage: <lua_file_name> <output_dir>

    -- Martin, 2026-09
    ```


## Modification

Modify files in [`src/`][src].


## Rebuilding

  * Clone [`workshop`][workshop] repo
  * Checkout it to date near "Updated" date from stats plate (at header of this Readme)
  * Modify `package.path` in [`builder/create_deploy.lua`][create_deploy]
    so it can find your cloned `workshop` repo
  * Run [`builder/rebuild.sh`][rebuild]


## Notes

  * There can be orphaned VM instructions in graphs. They are present
    in `luac -l` listing we are using. We're not going to eliminate them,
    our scope is show what is present, not generating nice graphs.

  * "Callgraph" name is a bit misleading

    We are making callgraph for VM instructions. On higher level
    it's called "flowchart".

  * It works for compiled and stripped Lua bytecode

    You don't need original sources.

  * Some functionality extensions are not planned

    Someone may think that adding coloring and shaping features
    in `.dot` files is improvement. We don't agree.

    If you want nice graph -- load `.tgf` into `yEd`. Apply one of it's
    layouts. Do shaping and coloring there as you please. Export to `.svg`.

  * Basically each function is "closure" and stored in separate file

    Building one graph for all closures is possible (and interesting)
    but result will be beyond our comprehension.

    Try tool on `builder/reformat_lua`. It will create over 500 graphs.
    Imagine them all merged into one graph. Not practical.


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
