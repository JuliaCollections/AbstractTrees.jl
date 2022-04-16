"""
    ParentLinks

Abstract type of the trait that indicates whether the parents of a node are stored.
"""
abstract type ParentLinks end

"""
    StoredParents <: ParentLinks

Indicates that this node stores parent links explicitly. The implementation
is responsible for defining the parentind function to expose this
information.
"""
struct StoredParents <: ParentLinks; end

"""
    ImplicitParents <: ParentLinks

Indicates that the tree does not store parents.  In these cases parents must be inferred from
the tree structure and cannot be inferred through a single node.
"""
struct ImplicitParents <: ParentLinks; end

"""
    parentlinks(::Type{T})
    parentlinks(tree)

A trait which indicates whether a tree node stores references to its parents (`StoredParents()`) or
if the parents must be inferred from the tree structure (`ImplicitParents()`).

Trees for which `parentlinks` returns `StoredParents()` *MUST* implement [`parent`](@ref).

**OPTIONAL**: This should be implemented for a tree if parents of nodes are stored
```julia
AbstractTrees.parentlinks(::Type{<:TreeType}) = AbstractTrees.StoredParents()
parent(t::TreeType) = get_parent(t)
```
"""
parentlinks(::Type) = ImplicitParents()
parentlinks(tree) = parentlinks(typeof(tree))

"""
    SiblingLinks

Abstract type of the trait that indicates whether siblings of a node are stored.
"""
abstract type SiblingLinks end

#TODO: do we care if something defines siblings(n)?
# probably, but I don't know where to use it yet
"""
    StoredSiblings <: SiblingLinks

Indicates that this tree node stores sibling links explicitly, or can compute them
quickly (e.g. because the tree has a (small) fixed branching ratio, so the
current index of a node can be determined by quick linear search).

Requires definition of `nextsibling` and `prevsibling` methods on a node.
"""
struct StoredSiblings <: SiblingLinks; end

"""
    ImplicitSiblings <: SiblingLinks

Indicates that tree nodes do not store references to siblings so that they must be inferred
from the tree structure.
"""
struct ImplicitSiblings <: SiblingLinks; end

"""
    siblinglinks(::Type{T})
    siblinglinks(tree)

A trait which indicates whether a tree node stores references to its siblings (`StoredSiblings()`) or
must be inferred from the tree structure (`ImplicitSiblings()`).

**OPTIONAL**: This should be implemented for a tree if siblings of nodes are stored
```julia
AbstractTrees.siblinglinks(::Type{<:TreeType}) = AbstractTrees.StoredSiblings()
```
"""
siblinglinks(::Type) = ImplicitSiblings()
siblinglinks(tree) = siblinglinks(typeof(tree))

#TODO: docs!!
"""
    ChildIndexing

Abstract type which indicates the access type of the tree.
"""
abstract type ChildIndexing end

# will assume if indexed has `length` because that's just way easier
struct IndexedChildren <: ChildIndexing end

struct NonIndexedChildren <: ChildIndexing end

childindexing(::Type) = NonIndexedChildren()
childindexing(node) = childindexing(typeof(node))

# this is dangerous if children is not efficient
childtype(node) = eltype(children(node))
