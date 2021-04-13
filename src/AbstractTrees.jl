"""
This package is intended to provide an abstract interface for working
with tree structures.
Though the package itself is not particularly sophisticated, it defines
the interface that can be used by other packages to talk about trees.
"""
module AbstractTrees

export print_tree, TreeCharSet, TreeIterator, Leaves, PostOrderDFS, Tree,
    AnnotationNode, StatelessBFS, treemap, treemap!, PreOrderDFS,
    ShadowTree, children

import Base: getindex, setindex!, iterate, nextind, print, show,
    eltype, IteratorSize, IteratorEltype, length, push!, pop!
using Base: SizeUnknown, EltypeUnknown


abstract type AbstractShadowTree end


"""
    children(x)

Get the immediate children of node `x`.

This is the primary function that needs to be implemented for custom tree types. It should return an
iterable object for which an appropriate implementation of `Base.pairs` is available.

The default behavior is to assume that if an object is iterable, iterating over
it gives its children. Non-iterable types are treated as leaf nodes.
"""
children(x) = Base.isiterable(typeof(x)) ? x : ()


include("traits.jl")
include("implicitstacks.jl")
include("printing.jl")
include("indexing.jl")
include("iteration.jl")
include("builtins.jl")


end # module
