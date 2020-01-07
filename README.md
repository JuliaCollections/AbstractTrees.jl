# AbstractTrees

[![Build Status](https://travis-ci.org/Keno/AbstractTrees.jl.svg?branch=master)](https://travis-ci.org/Keno/AbstractTrees.jl)

This package provides several utilities for working with tree-like data structures. Most importantly, it defines the `children` method that any package that contains such a datastructure may import and extend in order to take advantage of any generic tree algorithm in this package (or other packages compatible with this package).

# API overview

- `print_tree` pretty prints an arbitrary tree data structure.
- `Tree` is a simple wrapper around an arbitrary object that allows tree-indexing into that object (i.e. indexing with collections of indices specifying the child index at every level)
- `ShadowTree` is a tree object that combines two trees of equal structure into a single tree (indexing always produces another ShadowTree, but `setindex!` with tuples is allowed). Useful for adding annotation nodes to other trees without modifying that tree structure itself.
- `Leaves` is an iterator to visit the leaves of a tree in order.
- `PostOrderDFS` is a DFS (i.e. will vist node's children before it's lexicographically following siblings) that guarantees to visit children before their parents.
- `PreOrderDFS` is same as `PostOrderDFS` but visits parents before their children.
- `StatelessBFS` iterates over a tree level-by-level, but does not keep state (causing this to be O(n^2), but be able to handle changing trees).
- `treemap` maps each node of a tree to obtain a new tree.
- `treemap!` maps each node of a tree in place.

# Traits

- `AbstractTrees.nodetype(tree)` can be defined to make iteration inferrable.
- `AbstractTrees.ParentLinks` can be defined to return `AbstractTrees.StoredParents()`
  if a tree type stores explicit links to a parent; `AbstractTrees.SiblingLinks`,
  when set to `AbstractTrees.StoredSiblings()`, serves the same role for siblings.
  See their docstrings for more information.

# Breaking changes in v0.3

- `getindex(::Any, ::ImplicitRootState)` is no longer defined; packages
  that used this method will now throw a `MethodError`. To circumvent this,
  define `Base.getindex(x::MyTreeType, ::AbstractTrees.ImplicitRootState) = x`.
- By default, the iterators in this package now have the
  `Base.IteratorEltype` trait set to `Base.EltypeUnknown()`.
  This generally produces "narrower" (more concretely-typed) arrays when
  used in conjunction with `collect`.
  However, if you define the method `Base.eltype(::Type{<:TreeIterator{MyTreeType}})`,
  you should also set `Base.IteratorEltype(::Type{<:TreeIterator{MyTreeType}}) = Base.HasEltype()`.
