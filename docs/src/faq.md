```@meta
CurrentModule = AbstractTrees
```

# What are the breaking changes in 0.4?
Most trees which only define methods for the single-argument version of `children` should not be
affected by breaking changes in 0.4, though authors of packages containing these should review the
new trait system to ensure they have added any appropriate traits which can improve performance.

Iterators types do *not* have breaking changes.

There are quite a few breaking changes for features of AbstractTrees.jl which were not documented or
poorly documented and were therefore unlikely to be used.

The most significant changes are for indexed trees which now rely on the [`IndexNode`](@ref) object
and a dedicated set of methods.  Authors of packages using indexed trees should review [The Indexed
Tree Interface](@ref).  Roughly speaking, the changes are
- `children(tree, node)` ``\rightarrow`` `childindices(tree, node_index)`
- `Iterator(tree)` ``\rightarrow`` `Iterator(IndexNode(tree))`
- Check if your tree satisfies the [`StoredParents`](@ref) or [`StoredSiblings`](@ref) traits.
- Consider defining [`childrentype`](@ref) or [`childtype`](@ref) (can make some algorithms closer
    to type-stable).


# Why were breaking changes necessary for 0.4?
Prior to v0.4 AbstractTrees.jl confused the distinct concepts:
- A tree node.
- Values associated with the node (what is now obtained by [`nodevalue`](@ref)).
- The position of a node in a tree.
- A tree in its entirety.

This led to inconsistent implementations particularly of indexed tree types even within
AbstractTrees.jl itself.  As of 0.4 the package is much more firmly grounded in the concept of a
*node*, alternative methods for defining trees are simply adaptors from objects to nodes, in
particular [`IndexNode`](@ref).

A summary of major internal changes from 0.3 to 0.4 is as follows:
- All indexed tree methods of basic tree functions have been removed.  Indexed trees now have
    dedicated methods such as `childindices` and `parentindex`.
- Nodes can now implement `nodevalue` which allows for distinction between values associated with
    the nodes and the nodes themselves.
- All tree navigation is now based on "cursors".  A cursor provides the necessary information for
    moving between adjacent nodes of a tree.  Iterators now specify the movement among cursor
    nodes.
- Iterators now depend only on iterator states.  This is mostly for internal convenience and does not
    change the external API.
- `treemap` and `treemap!` have been replaced with versions that depend on [`MapNode`](@ref).

# Why aren't all iterators trees by default?
Iteration is very widely implemented for Julia types and there are many types which define iteration
but which don't make sense as trees.  Major examples in `Base` alone include `Number` and `String`,
`Char` and `Task`.  If there are this many examples in `Base` there are likely to be a lot more in
other packages.

# Why does `treemap` return a special node type?
As described above, older versions of this package conflate tree nodes with values attached to them.
This makes sense for certain built-in types, particularly arrays, but it imposes constraints on what
types of nodes a tree can have.  In particular, it requires all nodes to be container types (so that
they can contain their children).  It was previously not possible to have a tree in which, e.g. the
integer `1` was anything other than a leaf node.

The function `treemap` is special in that it must choose an appropriate output type for an entire
tree.  Nodes of this output tree cannot be chosen to be a simple array, since the contents of arrays
would be fully-determined by their children.  In other words, a `treemap` based on arrays can only
map leaves.

Introducing a new type becomes necessary to ensure that it can accommodate arbitrary output types.

