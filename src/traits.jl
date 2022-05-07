
"""
    ParentLinks(::Type{T})
    ParentLinks(tree)

A trait which indicates whether a tree node stores references to its parents (`StoredParents()`) or
if the parents must be inferred from the tree structure (`ImplicitParents()`).

Trees for which `parentlinks` returns `StoredParents()` *MUST* implement [`parent`](@ref).

If `StoredParents()`, all nodes in the tree must also have `StoredParents()`, otherwise use
`ImplicitParents()`.

**OPTIONAL**: This should be implemented for a tree if parents of nodes are stored
```julia
AbstractTrees.parentlinks(::Type{<:TreeType}) = AbstractTrees.StoredParents()
parent(t::TreeType) = get_parent(t)
```
"""
abstract type ParentLinks end

"""
    StoredParents <: ParentLinks

Indicates that this node stores parent links explicitly. The implementation
is responsible for defining the parentind function to expose this
information.

If a node in a tree has this trait, so must all connected nodes.  If this is not the case,
use [`ImplicitParents`](@ref) instead.

## Required Methods
- [`parent`](@ref)
"""
struct StoredParents <: ParentLinks; end

"""
    ImplicitParents <: ParentLinks

Indicates that the tree does not store parents.  In these cases parents must be inferred from
the tree structure and cannot be inferred through a single node.
"""
struct ImplicitParents <: ParentLinks; end

ParentLinks(::Type) = ImplicitParents()
ParentLinks(tree) = ParentLinks(typeof(tree))

"""
    SiblingLinks(::Type{T})
    SiblingLinks(tree)

A trait which indicates whether a tree node stores references to its siblings (`StoredSiblings()`) or
must be inferred from the tree structure (`ImplicitSiblings()`).

If a node has the trait `StoredSiblings()`, so must all connected nodes in the tree.  Otherwise,
use `ImplicitSiblings()` instead.

**OPTIONAL**: This should be implemented for a tree if siblings of nodes are stored
```julia
AbstractTrees.SiblingLinks(::Type{<:TreeType}) = AbstractTrees.StoredSiblings()
```
"""
abstract type SiblingLinks end

"""
    StoredSiblings <: SiblingLinks

Indicates that this tree node stores sibling links explicitly, or can compute them
quickly (e.g. because the tree has a (small) fixed branching ratio, so the
current index of a node can be determined by quick linear search).

If a node has this trait, so must all connected nodes in the tree.  Otherwise, use `ImplicitSiblings()` instead.

## Required Methods
- [`nextsibling`](@ref)
"""
struct StoredSiblings <: SiblingLinks; end

"""
    ImplicitSiblings <: SiblingLinks

Indicates that tree nodes do not store references to siblings so that they must be inferred
from the tree structure.
"""
struct ImplicitSiblings <: SiblingLinks; end

SiblingLinks(::Type) = ImplicitSiblings()
SiblingLinks(tree) = SiblingLinks(typeof(tree))

"""
    ChildIndexing(::Type{N})
    ChildIndexing(node)

A trait indicating whether the tree node `n` has children (as returned by [`children`](@ref)) which can be
indexed using 1-based indexing.

If a node has the `IndexedChildren()` so must all connected nodes in the tree.  Otherwise, use
`NonIndexedChildren()` instead.

Options are either [`NonIndexedChildren`](@ref) (default) or [`IndexedChildren`](@ref).
"""
abstract type ChildIndexing end

"""
    IndexedChildren <: ChildIndexing

Indicates that the object returned by `children(n)` where `n` is a tree node is indexable (1-based).

If a node has this trait so must all connected nodes in the tree.  Otherwise, use `NonIndexedChildren()` instead.

## Required Methods
- A node `node` with this trait must return an indexable object from `children(node)`.
"""
struct IndexedChildren <: ChildIndexing end

"""
    NonIndexedChildren <: ChildIndexing

Indicates that the object returned by `children(n)` where `n` is a tree node is not indexable (default).
"""
struct NonIndexedChildren <: ChildIndexing end

ChildIndexing(::Type) = NonIndexedChildren()
ChildIndexing(node) = ChildIndexing(typeof(node))


"""
    childrentype(::Type{T})
    childrentype(n)

Indicates the type of the children (the *collection* of children, not individual children) of the tree node `n`
or its type `T`.  [`children`](@ref) should return an object of this type.

If the `childrentype` can be inferred from the type of the node alone, the type `::Type{T}` definition is preferred
(the latter will fall back to it).

**OPTIONAL**: In most cases, [`childtype`](@ref) is used instead.  If `childtype` is not defined it will fall back
to `eltype ∘ childrentype`.
"""
childrentype(nodetype::Type) = Base._return_type(children, Tuple{nodetype})
childrentype(node) = typeof(children(node))

"""
    childtype(::Type{T})
    childtype(n)

Indicates the type of children of the tree node `n` or its type `T`.

If `childtype` can be inferred from the type of the node alone, the type `::Type{T}` definition is preferred
(the latter will fall back to it).

**OPTIONAL**: It is strongly recommended to define this wherever possible, as without it almost no tree algorithms
can be type-stable.  If `childrentype` is defined and can be known from the node type alone, this function will
fall back to `eltype(childrentype(T))`.  If this gives a correct result it's not necessary to define `childtype`.
"""
childtype(::Type{T}) where {T} = eltype(childrentype(T))
childtype(node) = eltype(childrentype(node))

"""
    childstatetype(::Type{T})
    childstatetype(n)

Indicates the type of the iteration state of the tree node `n` or its type `T`.  This is used by tree traversal
algorithms which must retain this state.  It therefore is necessary to define this to ensure that most tree
traversal is type stable.

**OPTIONAL**: Type inference is used to attempt to
"""
childstatetype(::Type{T}) where {T} = Iterators.approx_iter_type(childrentype(T))
childstatetype(node) = childstatetype(typeof(node))


#TODO: do a `nodetype` so we can have type stability for iteration of trees with common node type
