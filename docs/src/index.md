# AbstractTrees.jl


This package provides several utilities for working with tree-like data
structures. Most importantly, it defines the [`children`](@ref) method that any
package that contains such a data structure may import and extend in order to
take advantage of any generic tree algorithm in this package (or other packages
compatible with this package).


## API overview

* [`print_tree`](@ref) pretty prints an arbitrary tree data structure.
* [`Tree`](@ref) is a simple wrapper around an arbitrary object that allows tree-indexing into that object (i.e. indexing with collections of indices specifying the child index at every level).
* [`ShadowTree`](@ref) is a tree object that combines two trees of equal structure into a single tree (indexing always produces another `ShadowTree`, but `setindex!` with tuples is allowed). Useful for adding annotation nodes to other trees without modifying that tree structure itself.
* [`Leaves`](@ref) is an iterator to visit the leaves of a tree in order.
* [`PostOrderDFS`](@ref) is a depth-first search (i.e. will visit node's children before it's lexicographically following siblings) that guarantees to visit children before their parents.
* [`PreOrderDFS`](@ref) is same as `PostOrderDFS` but visits parents before their children.
* [`StatelessBFS`](@ref) iterates over a tree level-by-level, but does not keep state (causing this to be $O(n^2)$, but able to handle changing trees).
* [`treemap`](@ref) maps each node of a tree to obtain a new tree.
* [`treemap!`](@ref) maps each node of a tree in place.


## Traits

* [`AbstractTrees.nodetype(tree)`](@ref) can be defined to make iteration inferable.
* [`AbstractTrees.ParentLinks`](@ref) can be defined to return [`AbstractTrees.StoredParents()`](@ref) if a tree type stores explicit links to a parent; [`AbstractTrees.SiblingLinks`](@ref), when set to [`AbstractTrees.StoredSiblings()`](@ref), serves the same role for siblings. See their docstrings for more information.

## Examples

The [examples folder](https://github.com/JuliaCollections/AbstractTrees.jl/tree/master/examples) contains a number of usage examples of varying complexity.  
