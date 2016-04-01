# AbstractTrees

[![Build Status](https://travis-ci.org/Keno/AbstractTrees.jl.svg?branch=master)](https://travis-ci.org/Keno/AbstractTrees.jl)

This package provides several utilities for wokring with tree-like data structures. Most importantly, it defines the `children` method that any package that contains such a datastructure may import and extend in order to take advantage of any generic tree algorithm in this package (or other packages compatible with this package).

# API overview

- `print_tree` pretty prints an arbitrary tree data structure
- `Tree` a simple wrapper around an arbitrary object that allows tree-idexing into that object (i.e. indexing with collections of indices specifying the child index at every level).
- `ShadowTree` a tree object that combines two trees of equal structure into a single tree (indexing always produces another ShadowTree, but `setindex!` with tuples is allowed). Useful for adding annotation nodes to other trees without modifying that tree structure itself.
- `Leaves` an iterator to visit the leaves of a tree in order
- `PostOrderDFS` a DFS (i.e. will vist a node's children before it's lexicographically following siblings) that guarantees to visit children before their parents
- `PreeOrderDFS` same as `PostOrderDFS` but visits parents before their children.
- `StatelessBFS` Iterates over a tree level-by-level, but does not keep state (causing this to be O(N^2), but be able to handle changing trees)
- `treemap` Map each node of a tree to obtain a new tree
- `treemap!` Mach each node of a tree in place
