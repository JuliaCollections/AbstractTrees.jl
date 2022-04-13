"""
    AbstractTrees

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
struct ImplicitRootIndex end

"""
    Indexed{T}

A wrapper around a tree of type `T` for providing `getindex` methods.
"""
struct Indexed{T}
    tree::T
end
Base.getindex(tree::Indexed, ind) = tree.tree[ind]
Base.getindex(tree::Indexed, ::ImplicitRootIndex) = tree
rootindex(tree) = ImplicitRootIndex()

function children(i::Indexed, ind)
    Base.depwarn("No children overload for tree declared as indexed. Overloading childindices(...) is deprecated. Use children(::Indexed{MyTree}, index).", :childindices)
    return childindices(i.tree, ind)
end


include("traits.jl")
include("base.jl")
include("cursors.jl")
include("printing.jl")
include("indexing.jl")
include("iteration.jl")
include("builtins.jl")
include("wrappers.jl")


end # module
