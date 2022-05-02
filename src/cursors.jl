
"""
    TreeCursor{P,N}

Abstract type for tree cursors which when constructed from a node can be used to
navigate the entire tree descended from that node.

Tree cursors satisfy the abstract tree interface with a few additional guarantees:
- In addition to [`children`](@ref), [`parent`](@ref), [`nextsibling`](@ref) and
    optionally [`prevsibling`](@ref) must be defined.
- The above functions returning tree nodes are guaranteed to also return tree cursors.

Tree nodes which define `children` and have the traits [`StoredParents`](@ref) and
[`StoredSiblings`](@ref) satisfy the `TreeCursor` interface and can be used as such,
see [`treecursor`](@ref).
"""
abstract type TreeCursor{P,N} end

unwrapedtype(::Type{<:TreeCursor{P,N}}) where {P,N} = N
unwrapedtype(csr::TreeCursor) = unwrapedtype(typeof(csr))

# note that this is guaranteed to return another of the same type of TreeCursor
parenttype(::Type{<:TreeCursor{P,N}}) where {P,N} = P
parenttype(csr::TreeCursor) = parenttype(typeof(csr))

# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor{P,N}}) where {P,N} = IteratorSize(childtype(N))

Base.length(tc::TreeCursor) = (length ∘ children ∘ unwrap)(csr)

Base.IteratorEltype(::Type{<:TreeCursor}) = EltypeUnknown()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc

ChildIndexing(tc::TreeCursor) = ChildIndexing(unwrap(tc))

unwrap(tc::TreeCursor) = tc.node

parent(tc::TreeCursor) = tc.parent


struct InitialState end


# this version assumes all we can do is call `children`… if even that is inefficient you're fucked
struct ImplicitCursor{P,N,S} <: TreeCursor{P,N}
    parent::P
    node::N
    sibling_state::S

    ImplicitCursor(p::Union{Nothing,ImplicitCursor}, n, s=InitialState()) = new{typeof(p),typeof(n),typeof(s)}(p, n, s)
end

ImplicitCursor(node) = ImplicitCursor(nothing, node)

Base.IteratorEltype(::Type{<:ImplicitCursor}) = HasEltype()

function Base.eltype(::Type{ImplicitCursor{P,N,S}}) where {P,N,S}
    cst = (childstatetype ∘ unwrapedtype)(P)
    P′ = ImplicitCursor{P,N,S}
    ImplicitCursor{P′,childtype(N),cst}
end

function Base.eltype(csr::ImplicitCursor)
    cst = (childstatetype ∘ parent ∘ unwrap)(csr)
    ImplicitCursor{typeof(csr),childtype(unwrap(csr)),cst}
end

function Base.iterate(csr::ImplicitCursor, (c, s)=(nothing, InitialState()))
    cs = (children ∘ unwrap)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = ImplicitCursor(csr, n′, s′)
    (o, (o, s′))
end

function nextsibling(csr::ImplicitCursor)
    isroot(csr) && return nothing
    cs = (children ∘ unwrap ∘ parent)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = csr.sibling_state isa InitialState ? iterate(cs) : iterate(cs, csr.sibling_state)
    isnothing(r) && return nothing
    (n′, s′) = r
    ImplicitCursor(parent(csr), n′, s′)
end


# this is still useful because it simplifies what the "user" has to do to specify the types
struct IndexedCursor{P,N} <: TreeCursor{P,N}
    parent::P
    node::N
    index::Int

    IndexedCursor(p::Union{Nothing,IndexedCursor}, n, idx::Integer=1) = new{typeof(p),typeof(n)}(p, n, idx)
end

IndexedCursor(node) = IndexedCursor(nothing, node)

Base.IteratorSize(::Type{<:IndexedCursor}) = HasLength()
Base.IteratorEltype(::Type{<:IndexedCursor}) = HasEltype()

function Base.eltype(::Type{IndexedCursor{P,N}}) where {P,N}
    P′ = IndexedCursor{P,N}
    IndexedCursor{P′,childtype(N)}
end
Base.eltype(csr::IndexedCursor) = IndexedCursor{typeof(csr),childtype(unwrap(csr))}
Base.length(csr::IndexedCursor) = (length ∘ children ∘ unwrap)(csr)

function Base.getindex(csr::IndexedCursor, idx)
    cs = (children ∘ unwrap)(csr)
    IndexedCursor(csr, cs[idx], idx)
end

function Base.iterate(csr::IndexedCursor, idx=1)
    idx > length(csr) && return nothing
    (csr[idx], idx+1)
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


struct SiblingCursor{P,N} <: TreeCursor{P,N}
    parent::P
    node::N

    SiblingCursor(p::Union{Nothing,SiblingCursor}, n) = new{typeof(p),typeof(n)}(p, n)
end

SiblingCursor(node) = SiblingCursor(nothing, node)

Base.IteratorSize(::Type{SiblingCursor{P,N}}) where {P,N} = IteratorSize(childtype(N))

Base.IteratorEltype(::Type{<:SiblingCursor}) = HasEltype()

function Base.eltype(::Type{SiblingCursor{P,N}}) where {P,N}
    cst = (childstatetype ∘ unwrapedtype)(P)
    P′ = SiblingCursor{P,N}
    SiblingCursor{P′,childtype(N)}
end

Base.eltype(csr::SiblingCursor) = SiblingCursor{typeof(csr),childtype(unwrap(csr))}

function Base.iterate(csr::SiblingCursor, (c, s)=(nothing, InitialState()))
    cs = (children ∘ unwrap)(csr)
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = SiblingCursor(csr, n′)
    (o, (o, s′))
end

function nextsibling(csr::SiblingCursor)
    n = nextsibling(unwrap(csr))
    SiblingCursor(parent(csr), n)
end

function prevsibling(csr::SiblingCursor)
    p = prevsibling(unwrap(csr))
    SiblingCursor(parent(csr), p)
end


TreeCursor(::NonIndexedChildren, node) = ImplicitCursor(node)
TreeCursor(::IndexedChildren, node) = IndexedCursor(node)

TreeCursor(::ImplicitSiblings, node) = TreeCursor(ChildIndexing(node), node)
TreeCursor(::StoredSiblings, node) = SiblingCursor(node)

TreeCursor(node) = TreeCursor(SiblingLinks(node), node)

# this has a different name because it may not return TreeCursor
treecursor(::ImplicitParents, node) = TreeCursor(node)
treecursor(::StoredParents, node) = node
treecursor(node) = treecursor(ParentLinks(node), node)
