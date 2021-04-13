"""
This package is intended to provide an abstract interface for working
with tree structures.
Though the package itself is not particularly sophisticated, it defines
the interface that can be used by other packages to talk about trees.
"""
module AbstractTrees

export children, childcount, isleaf, ischild, intree, isdescendant, treesize, treebreadth, treeheight
export print_tree, TreeCharSet
export TreeIterator, Leaves, PostOrderDFS, PreOrderDFS, StatelessBFS
export Tree, ShadowTree, AnnotationNode, treemap, treemap!

import Base: getindex, setindex!, iterate, nextind, print, show,
    eltype, IteratorSize, IteratorEltype, length, push!, pop!
using Base: SizeUnknown, EltypeUnknown


abstract type AbstractShadowTree end


include("traits.jl")
include("base.jl")
include("implicitstacks.jl")
include("printing.jl")
include("indexing.jl")
include("iteration.jl")
include("builtins.jl")


end # module
