
"""
    InitialState

A type used for some AbstractTrees.jl iterators to indicate that iteration is in its initial state.
Typically this is used for wrapper types to indicate that the `iterate` function has not yet  been called
on the wrapped object.
"""
struct InitialState end


"""
    TreeCursor{N,P}

Abstract type for tree cursors which when constructed from a node can be used to
navigate the entire tree descended from that node.

Tree cursors satisfy the abstract tree interface with a few additional guarantees:
- Tree cursors all have the [`StoredParents`](@ref) and [`StoredSiblings`](@ref) traits.
- All functions acting on a cursor which returns a tree node is guaranteed to return another `TreeCursor`.
    For example, `children`, `parent` and `nextsiblin` all return a `TreeCursor` of the same type as
    the argument.

Tree nodes which define `children` and have the traits [`StoredParents`](@ref) and
[`StoredSiblings`](@ref) satisfy the `TreeCursor` interface, but calling `TreeCursor(node)` on such
a node wraps them in a [`TrivialCursor`](@ref) to maintain a consistent interface.

Note that any `TreeCursor` created from a non-cursor node is the root of its own tree, but can be created
from any tree node.  For example the cursor created from the tree `[1,[2,3]]` corresponding to node with
value `[2,3]` has no parent and children `2` and `3`.  This is because a cursor created this way cannot
infer the iteration state of its siblings.  These constructors are still allowed so that users can
run tree algorithms over non-root nodes but they do not permit ascension from the initial node.

## Constructors
All `TreeCursor`s possess (at least) the following constructors
- `T(node)`
- `T(parent, node)`

In the former case the `TreeCursor` is constructed for the tree of which `node` is the root.
"""
abstract type TreeCursor{N,P} end

"""
    nodevaluetype(csr::TreeCursor)

Get the type of the wrapped node.  This should match the return type of [`nodevalue`](@ref).
"""
nodevaluetype(::Type{<:TreeCursor{N,P}}) where {N,P} = N
nodevaluetype(csr::TreeCursor) = nodevaluetype(typeof(csr))

"""
    parenttype(csr::TreeCursor)

The return type of `parent(csr)`.  For properly constructed `TreeCursor`s this is guaranteed to be another
`TreeCursor`.
"""
parenttype(::Type{<:TreeCursor{N,P}}) where {N,P} = P
parenttype(csr::TreeCursor) = parenttype(typeof(csr))

# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor{N,P}}) where {N,P} = Base.IteratorSize(childrentype(N))

Base.length(tc::TreeCursor) = length(children(nodevalue(tc)))

# this is needed in case an iterator declares IteratorSize to be HasSize
Base.size(tc::TreeCursor) = size(children(nodevalue(tc)))

Base.IteratorEltype(::Type{<:TreeCursor}) = EltypeUnknown()

ParentLinks(::Type{<:TreeCursor}) = StoredParents()

SiblingLinks(::Type{<:TreeCursor}) = StoredSiblings()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc

ChildIndexing(tc::TreeCursor) = ChildIndexing(nodevalue(tc))

nodevalue(tc::TreeCursor) = tc.node

parent(tc::TreeCursor) = tc.parent


#====================================================================================================
Note for developers:

The following code for `TreeCursor` types contains a fair amount of code duplication.
In particular, some of the cursors can probably be combined (e.g. ImplicitCursor and StableCursor).

This duplication is deliberate: cursors can get very subtle and it is rather easy to break them,
break their type stability or cause O(tree_depth) recursive compilation costs.
====================================================================================================#


"""
    TrivialCursor{N,P} <: TreeCursor{N,P}

A [`TreeCursor`](@ref) which matches the functionality of the underlying node.  Tree nodes wrapped by this
cursor themselves have most of the functionality required of a `TreeCursor`, this type exists entirely
for the sake of maintaining a fully consistent interface with other `TreeCursor` objects.
"""
struct TrivialCursor{N,P} <: TreeCursor{N,P}
    parent::P  # unlike in most other cursors, this is not a cursor
    node::N
end

function parent(csr::TrivialCursor)
    isnothing(csr.parent) && return nothing
    TrivialCursor(parent(csr.parent), csr.parent)
end

TrivialCursor(node) = TrivialCursor(parent(node), node)

function Base.iterate(csr::TrivialCursor, s=InitialState())
    cs = children(nodevalue(csr))
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = TrivialCursor(n′)
    (o, (o, s′))
end

function nextsibling(csr::TrivialCursor)
    n = nextsibling(csr.node)
    isnothing(n) ? nothing : TrivialCursor(csr.parent, n)
end

function prevsibling(csr::TrivialCursor)
    p = prevsibling(csr.node)
    isnothing(p) ? nothing : TrivialCursor(csr.parent, p)
end


"""
    ImplicitCursor{N,P,S} <: TreeCursor{N,P}

A [`TreeCursor`](@ref) which wraps nodes which cannot efficiently access either their parents or siblings directly.
This should be thought of as a "worst case scenario" tree cursor.  In particular, `ImplicitCursor`s store the
child iteration state of type `S` and for any of `ImplicitCursor`s method to be type-stable it must be possible
to infer the child iteration state type, see [`childstatetype`](@ref).
"""
struct ImplicitCursor{N,P,S} <: TreeCursor{N,P}
    parent::Union{Nothing,ImplicitCursor}
    node::N
    nextsibstate::S

    function ImplicitCursor(p::Union{Nothing,ImplicitCursor}, n, s)
        cst = isnothing(p) ? Any : childstatetype(nodevalue(p))
        new{typeof(n),typeof(nodevalue(p)),cst}(p, n, s)
    end
end

ImplicitCursor(node) = ImplicitCursor(nothing, node, nothing)

Base.IteratorEltype(::Type{<:ImplicitCursor}) = EltypeUnknown()

function Base.eltype(::Type{ImplicitCursor{N,P,S}}) where {N,P,S}
    ImplicitCursor{childtype(N),N,childstatetype(P)}
end

function Base.eltype(csr::ImplicitCursor)
    cst = childstatetype(parent(nodevalue(csr)))
    ImplicitCursor{childtype(nodevalue(csr)),nodevaluetype(csr),cst}
end

function Base.iterate(csr::ImplicitCursor, s=InitialState())
    cs = children(nodevalue(csr))
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    # next cursor requires 1 extra iteration to store next sibling
    ns = iterate(cs, s′)
    o = ImplicitCursor(csr, n′, ns)
    (o, s′)
end

function nextsibling(csr::ImplicitCursor)
    st = csr.nextsibstate
    isnothing(st) && return nothing
    (n, s) = st
    ns = iterate(children(nodevalue(parent(csr))), s)
    ImplicitCursor(csr.parent, n, ns)
end


"""
    IndexedCursor{N,P} <: TreeCursor{N,P}

A [`TreeCursor`](@ref) for tree nodes with the [`IndexedChildren`](@ref) trait but for which parents and siblings
are not directly accessible.

This type is very similar to [`ImplicitCursor`](@ref) except that it is free to assume that the child iteration
state is an integer starting at `1` which drastically simplifies type inference and slightly simplifies the
iteration methods.
"""
struct IndexedCursor{N,P} <: TreeCursor{N,P}
    parent::Union{Nothing,IndexedCursor}
    node::N
    index::Int

    IndexedCursor(p::Union{Nothing,IndexedCursor}, n, idx::Integer=1) = new{typeof(n),typeof(nodevalue(p))}(p, n, idx)
end

IndexedCursor(node) = IndexedCursor(nothing, node)

Base.IteratorSize(::Type{<:IndexedCursor}) = HasLength()

Base.eltype(::Type{IndexedCursor{N,P}}) where {N,P} = IndexedCursor{childtype(N),N}
Base.eltype(csr::IndexedCursor) = IndexedCursor{childtype(nodevalue(csr)),nodevaluetype(csr)}
Base.length(csr::IndexedCursor) = length(children(nodevalue(csr)))

function Base.getindex(csr::IndexedCursor, idx)
    cs = children(nodevalue(csr))
    IndexedCursor(csr, cs[idx], idx)
end

function Base.iterate(csr::IndexedCursor, idx=1)
    idx > length(csr) && return nothing
    (csr[idx], idx + 1)
end

function nextsibling(csr::IndexedCursor)
    p = parent(csr)
    isnothing(p) && return nothing
    idx = csr.index + 1
    idx > length(p) && return nothing
    p[idx]
end

function prevsibling(csr::IndexedCursor)
    idx = csr.index - 1
    idx < 1 && return nothing
    parent(csr)[idx]
end


"""
    SiblingCursor{N,P} <: TreeCursor{N,P}

A [`TreeCursor`](@ref) for trees with the [`StoredSiblings`](@ref) trait.
"""
struct SiblingCursor{N,P} <: TreeCursor{N,P}
    parent::Union{Nothing,SiblingCursor}
    node::N

    SiblingCursor(p::Union{Nothing,SiblingCursor}, n) = new{typeof(n),typeof(nodevalue(p))}(p, n)
end

SiblingCursor(node) = SiblingCursor(nothing, node)

Base.IteratorEltype(::Type{<:SiblingCursor}) = HasEltype()

Base.eltype(::Type{SiblingCursor{N,P}}) where {N,P} = SiblingCursor{childtype(N),N}

function Base.iterate(csr::SiblingCursor, s=InitialState())
    cs = children(nodevalue(csr))
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = SiblingCursor(csr, n′)
    (o, s′)
end

function nextsibling(csr::SiblingCursor)
    n = nextsibling(nodevalue(csr))
    isnothing(n) ? nothing : SiblingCursor(parent(csr), n)
end

function prevsibling(csr::SiblingCursor)
    p = prevsibling(nodevalue(csr))
    isnothing(p) ? nothing : SiblingCursor(parent(csr), p)
end


struct StableCursor{N,S} <: TreeCursor{N,N}
    parent::Union{Nothing,StableCursor{N,S}}
    node::N
    # includes the full return type of `iterate` for siblings and is guaranteed to be a
    # Union{Nothing,T} type
    nextsibstate::S

    # note that this very deliberately takes childstatetype(n) and *not* childstatetype(p)
    # this is because p may be nothing
    StableCursor(::Nothing, n, st) = new{typeof(n),childstatetype(n)}(nothing, n, st)

    # this method is important for eliminating expensive calls to childstatetype
    StableCursor(p::StableCursor{N,S}, n, st) where {N,S} = new{N,S}(p, n, st)
end

StableCursor(node) = StableCursor(nothing, node, nothing)

Base.IteratorEltype(::Type{<:StableCursor}) = HasEltype()

Base.eltype(::Type{T}) where {T<:StableCursor} = T

function Base.iterate(csr::StableCursor, s=InitialState())
    cs = children(nodevalue(csr))
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    # next cursor requires 1 extra iteration to store next sibling
    ns = iterate(cs, s′)
    o = StableCursor(csr, n′, ns)
    (o, s′)
end

function nextsibling(csr::StableCursor)
    st = csr.nextsibstate
    isnothing(st) && return nothing
    # if we got here it also guarantees that there are more siblings
    (n, s) = st
    ns = iterate(children(nodevalue(parent(csr))), s)
    StableCursor(csr.parent, n, ns)
end


struct StableIndexedCursor{N} <: TreeCursor{N,N}
    parent::Union{Nothing,StableIndexedCursor{N}}
    node::N
    index::Int

    StableIndexedCursor(p::Union{Nothing,StableIndexedCursor}, n, idx::Integer=1) = new{typeof(n)}(p, n, idx)
end

StableIndexedCursor(node) = StableIndexedCursor(nothing, node)

Base.IteratorSize(::Type{<:StableIndexedCursor}) = HasLength()

Base.IteratorEltype(::Type{<:StableIndexedCursor}) = HasEltype()

Base.eltype(::Type{T}) where {T<:StableIndexedCursor} = T

Base.length(csr::StableIndexedCursor) = length(children(nodevalue(csr)))

function Base.getindex(csr::StableIndexedCursor, idx)
    cs = children(nodevalue(csr))
    StableIndexedCursor(csr, cs[idx], idx)
end

function Base.iterate(csr::StableIndexedCursor, idx=1)
    idx > length(csr) && return nothing
    (csr[idx], idx + 1)
end

function nextsibling(csr::StableIndexedCursor)
    p = parent(csr)
    isnothing(p) && return nothing
    idx = csr.index + 1
    idx > length(p) && return nothing
    p[idx]
end

function prevsibling(csr::StableIndexedCursor)
    idx = csr.index - 1
    idx < 1 && return nothing
    parent(csr)[idx]
end


TreeCursor(node) = TreeCursor(NodeType(node), ChildIndexing(node), ParentLinks(node), SiblingLinks(node), node)

TreeCursor(::HasNodeType, ::IndexedChildren, ::ParentLinks, ::SiblingLinks, node) = StableIndexedCursor(node)
TreeCursor(::HasNodeType, ::NonIndexedChildren, ::ParentLinks, ::SiblingLinks, node) = StableCursor(node)

TreeCursor(::NodeTypeUnknown, ::IndexedChildren, ::ParentLinks, ::SiblingLinks, node) = IndexedCursor(node)
TreeCursor(::NodeTypeUnknown, ::IndexedChildren, ::ImplicitParents, ::StoredSiblings, node) = IndexedCursor(node)

TreeCursor(::NodeTypeUnknown, ::ChildIndexing, ::StoredParents, ::StoredSiblings, node) = TrivialCursor(node)

TreeCursor(::NodeTypeUnknown, ::ChildIndexing, ::ImplicitParents, ::StoredSiblings, node) = SiblingCursor(node)

TreeCursor(::NodeTypeUnknown, ::NonIndexedChildren, ::ParentLinks, ::ImplicitSiblings, node) = ImplicitCursor(node)

# extra methods to resolve ambiguity
TreeCursor(::NodeTypeUnknown, ::IndexedChildren, ::StoredParents, ::StoredSiblings, node) = TrivialCursor(node)
TreeCursor(::NodeTypeUnknown, ::NonIndexedChildren, ::StoredParents, ::StoredSiblings, node) = TrivialCursor(node)
