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


# MAJOR ISSUES:
# - everything assumes that `children` is very cheap, will have to do quite a lot to handle the
#   cases where it is not (and it will involve a lot of different possibilities)


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

#TODO: functions to add
#- getroot


#interface
export children, parentlinks, siblinglinks, childindexing, childtype
#extended interface
export nextsibling, prevsibling

# properties
export haschildren, ischild, isroot, isroot, intree, isdescendant, treesize, treebreadth, treeheight

# cursors
export TreeCursor, ImplicitCursor, SiblingCursor

#indexing
export childindex, indexed


end # module
