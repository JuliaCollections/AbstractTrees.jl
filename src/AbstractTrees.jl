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


abstract type AbstractShadowTree end

struct ImplicitRootIndex end

include("traits.jl")
include("base.jl")
include("indexing.jl")
include("cursors.jl")
#include("printing.jl")
include("iteration.jl")
#include("builtins.jl")
#include("wrappers.jl")


#interface
export children, parentlinks, siblinglinks, childindexing, childtype
#extended interface
export nextsibling, prevsibling

# properties
export ischild, isroot, isroot, intree, isdescendant, treesize, treebreadth, treeheight, descendleft, getroot

# cursors
export TreeCursor, ImplicitCursor, SiblingCursor

#indexing
export childindex, indexed


end # module
