"""
This package is intended to provide an abstract interface for working
with tree structures.
Though the package itself is not particularly sophisticated, it defines
the interface that can be used by other packages to talk about trees.
"""
module AbstractTrees

export children, ischild, intree, isdescendant, treesize, treebreadth, treeheight
export print_tree, TreeCharSet
export TreeIterator, Leaves, PostOrderDFS, PreOrderDFS, StatelessBFS
export Tree, ShadowTree, AnnotationNode, treemap, treemap!, Indexed

import Base: getindex, setindex!, iterate, nextind, print, show,
    eltype, IteratorSize, IteratorEltype, length, push!, pop!
using Base: SizeUnknown, EltypeUnknown


abstract type AbstractShadowTree end
struct ImplicitRootIndex; end

struct Indexed{T}; tree::T; end
Base.getindex(tree::Indexed, ind) = tree.tree[ind]
Base.getindex(tree::Indexed, ::ImplicitRootIndex) = tree
rootindex(tree) = ImplicitRootIndex()

"""
    children([tree,] x)

Get the immediate children of node `x` (optionally in the context of tree `tree`).

This is the primary function that needs to be implemented for custom tree types. It should return an
iterable object for which an appropriate implementation of `Base.pairs` is available.

The default behavior is to assume that if an object is iterable, iterating over
it gives its children. Non-iterable types are treated as leaf nodes.
"""
children(x) = Base.isiterable(typeof(x)) ? x : ()
children(tree, node) = children(node)

function children(i::Indexed, ind)
    Base.depwarn("No children overload for tree declared as indexed. Overloading childindices(...) is deprecated. Use children(::Indexed{MyTree}, index).", :childindices)
    return childindices(i.tree, ind)
end

"""
    parent([tree,] x)

Get the immediate parent of a node `x`

This function should be implemented for trees that have stored parents.
"""
parent(tree, x) = parent(x)

isroot(tree, x) = parent(tree, x) === nothing
isroot(x) = parent(x) === nothing

has_children(x) = children(x) !== ()


include("traits.jl")
include("cursors.jl")
include("printing.jl")
include("indexing.jl")
include("iteration.jl")
include("builtins.jl")
include("wrappers.jl")


end # module
