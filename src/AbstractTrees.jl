"""
    AbstractTrees

This package is intended to provide an abstract interface for working
with tree structures.
Though the package itself is not particularly sophisticated, it defines
the interface that can be used by other packages to talk about trees.
"""
module AbstractTrees

using Base: HasLength, SizeUnknown, HasEltype, EltypeUnknown


include("traits.jl")
include("base.jl")
include("indexing.jl")
include("cursors.jl")
include("iteration.jl")
include("builtins.jl")
include("printing.jl")

# Julia 1.0 support (delete when we no longer support it)
if !isdefined(Base, :isnothing)
    isnothing(x) = x === nothing
end


#interface
export ParentLinks, StoredParents, ImplicitParents
export SiblingLinks, StoredSiblings, ImplicitSiblings
export ChildIndexing, IndexedChildren, NonIndexedChildren
export NodeType, HasNodeType, NodeTypeUnknown
export nodetype, nodevalue, nodevalues, children, childtype, childrentype
#extended interface
export nextsibling, prevsibling

export AbstractNode, StableNode

# properties
export ischild, isroot, isroot, intree, isdescendant, treesize, treebreadth, treeheight, descendleft, getroot

# cursors
export TreeCursor, TrivialCursor, ImplicitCursor, SiblingCursor

#indexing
export getdescendant, childindices, rootindex, parentindex, nextsiblingindex, prevsiblingindex, IndexNode

# iteration
export TreeIterator, PreOrderDFS, PostOrderDFS, Siblings, Leaves, StatelessBFS, MapNode
export treemap

# printing
export print_tree, repr_tree


end # module
