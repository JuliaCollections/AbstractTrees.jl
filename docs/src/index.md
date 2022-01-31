# AbstractTrees.jl

Trees come in many shapes and sizes. For some, the tree structure is explicit,
for some implicit. Some store links to their children and parents. Others don't.
Some have stored or easily computable children, for others (e.g. file system
trees) accessing the list of children can be quite expensive. As such, providing
(efficient) abstractions over these various kinds of data structures is no easy
task.

This package provides common interfaces for packages working with tree-like data structures.
It does not itself provide any particular tree structure, but is designed to be easy to integrate.
For most tree implimentations, the tree interface should be declarable little or no additional code.

The most important interface in this library is the [`children`](@ref) method that allows
any arbitrary data structures to take advantage of any generic tree algorithm in this package
(or other packages compatible with this package).


## Package overview

* A common interface to arbitrary tree-like data structures, primarily through the [`children`](@ref) function.
* Pretty-printing trees with [`print_tree`](@ref).
* Tree traversal utilities:
    * [`Leaves`](@ref) is an iterator to visit the leaves of a tree in order.
    * [`PostOrderDFS`](@ref) is a depth-first search (i.e. will visit node's children before it's lexicographically following siblings) that guarantees to visit children before their parents.
    * [`PreOrderDFS`](@ref) is same as `PostOrderDFS` but visits parents before their children.
    * [`StatelessBFS`](@ref) iterates over a tree level-by-level, but does not keep state (causing this to be $O(n^2)$, but able to handle changing trees).
* [`Tree`](@ref) is a simple wrapper around an arbitrary object that allows tree-indexing into that object (i.e. indexing with collections of indices specifying the child index at every level).
* [`ShadowTree`](@ref) is a tree object that combines two trees of equal structure into a single tree (indexing always produces another `ShadowTree`, but `setindex!` with tuples is allowed). Useful for adding annotation nodes to other trees without modifying that tree structure itself.
* [`treemap`](@ref) maps each node of a tree to obtain a new tree.
* [`treemap!`](@ref) maps each node of a tree in place.
