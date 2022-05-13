
struct InitialState end


"""
    TreeCursor{P,N}

Abstract type for tree cursors which when constructed from a node can be used to
navigate the entire tree descended from that node.

Tree cursors satisfy the abstract tree interface with a few additional guarantees:
- In addition to [`children`](@ref), [`parent`](@ref), [`nextsibling`](@ref) and
    optionally [`prevsibling`](@ref) must be defined.
- The above functions returning tree nodes are guaranteed to also return tree cursors.

Tree nodes which define `children` and have the traits [`StoredParents`](@ref) and
[`StoredSiblings`](@ref) satisfy the `TreeCursor` interface and can be used as such.
"""
abstract type TreeCursor{P,N} end

nodevalueedtype(::Type{<:TreeCursor{P,N}}) where {P,N} = N
nodevalueedtype(csr::TreeCursor) = unwrapedtype(typeof(csr))

# note that this is guaranteed to return another of the same type of TreeCursor
parenttype(::Type{<:TreeCursor{P,N}}) where {P,N} = P
parenttype(csr::TreeCursor) = parenttype(typeof(csr))

# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor{P,N}}) where {P,N} = IteratorSize(childtype(N))

Base.length(tc::TreeCursor) = (length ∘ children ∘ nodevalue)(csr)

Base.IteratorEltype(::Type{<:TreeCursor}) = EltypeUnknown()

ParentLinks(::Type{<:TreeCursor}) = StoredParents()

SiblingLinks(::Type{<:TreeCursor}) = StoredSiblings()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc

ChildIndexing(tc::TreeCursor) = ChildIndexing(nodevalue(tc))

nodevalue(tc::TreeCursor) = tc.node

parent(tc::TreeCursor) = tc.parent


# this exists mostly for the sake of guaranteeing a uniform interface
struct TrivialCursor{P,N} <: TreeCursor{P,N}
    parent::P
    node::N
end

parent(csr::TrivialCursor) = parent(csr.node)

TrivialCursor(node) = TrivialCursor(parent(node), node)

function Base.iterate(csr::TrivialCursor, s=InitialState())
    cs = (children ∘ nodevalue)(csr)
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
    cst = (childstatetype ∘ nodevalueedtype)(P)
    P′ = ImplicitCursor{P,N,S}
    ImplicitCursor{P′,childtype(N),cst}
end

function Base.eltype(csr::ImplicitCursor)
    cst = (childstatetype ∘ parent ∘ nodevalue)(csr)
    ImplicitCursor{typeof(csr),childtype(nodevalue(csr)),cst}
end

function Base.iterate(csr::ImplicitCursor, s=InitialState())
    cs = (children ∘ nodevalue)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = ImplicitCursor(csr, n′, s′)
    (o, s′)
end

function nextsibling(csr::ImplicitCursor)
    isroot(csr) && return nothing
    cs = (children ∘ nodevalue ∘ parent)(csr)
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

function Base.eltype(::Type{IndexedCursor{P,N}}) where {P,N}
    P′ = IndexedCursor{P,N}
    IndexedCursor{P′,childtype(N)}
end
Base.eltype(csr::IndexedCursor) = IndexedCursor{typeof(csr),childtype(nodevalue(csr))}
Base.length(csr::IndexedCursor) = (length ∘ children ∘ nodevalue)(csr)

function Base.getindex(csr::IndexedCursor, idx)
    cs = (children ∘ nodevalue)(csr)
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
    cst = (childstatetype ∘ nodevalueedtype)(P)
    P′ = SiblingCursor{P,N}
    SiblingCursor{P′,childtype(N)}
end

Base.eltype(csr::SiblingCursor) = SiblingCursor{typeof(csr),childtype(nodevalue(csr))}

function Base.iterate(csr::SiblingCursor, (c, s)=(nothing, InitialState()))
    cs = (children ∘ nodevalue)(csr)
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = SiblingCursor(csr, n′)
    (o, (o, s′))
end

function nextsibling(csr::SiblingCursor)
    n = nextsibling(nodevalue(csr))
    SiblingCursor(parent(csr), n)
end

function prevsibling(csr::SiblingCursor)
    p = prevsibling(nodevalue(csr))
    SiblingCursor(parent(csr), p)
end


TreeCursor(::ChildIndexing, ::StoredParents, ::StoredSiblings, node) = TrivialCursor(node)

TreeCursor(::ChildIndexing, ::ImplicitParents, ::StoredSiblings, node) = SiblingCursor(node)

TreeCursor(::NonIndexedChildren, ::ParentLinks, ::ImplicitSiblings, node) = ImplicitCursor(node)
TreeCursor(::IndexedChildren, ::ParentLinks, ::ImplicitSiblings, node) = IndexedCursor(node)

TreeCursor(node) = TreeCursor(ChildIndexing(node), ParentLinks(node), SiblingLinks(node), node)
