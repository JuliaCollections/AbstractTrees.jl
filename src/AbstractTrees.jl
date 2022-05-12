"""
    AbstractTrees

This package is intended to provide an abstract interface for working
with tree structures.
Though the package itself is not particularly sophisticated, it defines
the interface that can be used by other packages to talk about trees.
"""
module AbstractTrees

using Base: HasLength, SizeUnknown, HasEltype, EltypeUnknown

# this should be removed for commits
using Infiltrator


include("traits.jl")
include("base.jl")
include("indexing.jl")
include("cursors.jl")
include("iteration.jl")
include("builtins.jl")
include("printing.jl")


#interface
export ParentLinks, StoredParents, ImplicitParents
export SiblingLinks, StoredSiblings, ImplicitSiblings
export ChildIndexing, IndexedChildren, NonIndexedChildren
export children, parentlinks, siblinglinks, childindexing, childtype, childrentype
#extended interface
export nextsibling, prevsibling

# properties
export ischild, isroot, isroot, intree, isdescendant, treesize, treebreadth, treeheight, descendleft, getroot

# cursors
export TreeCursor, TrivialCursor, ImplicitCursor, SiblingCursor

#indexing
export childindex, indexed

# iteration
export TreeIterator, PreOrderDFS, PostOrderDFS, Siblings, Leaves, StatelessBFS, MapNode
export treemap

# printing
export print_tree


end # module
