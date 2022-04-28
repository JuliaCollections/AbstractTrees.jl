
abstract type TreeCursor{P,N} end

#TODO: type stability is mostly impossible but we still have to ensure we can make the cases
# where the underlying nodes define everything typestable

nodetype(::Type{<:TreeCursor{P,N}}) where {P,N} = N
nodetype(csr::TreeCursor) = nodetype(typeof(csr))

# note that this is guaranteed to return another of the same type of TreeCursor
parenttype(::Type{<:TreeCursor{P,N}}) where {P,N} = P
parenttype(csr::TreeCursor) = parenttype(typeof(csr))

# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor}) = SizeUnknown()

Base.IteratorEltype(::Type{<:TreeCursor}) = EltypeUnknown()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc

ChildIndexing(tc::TreeCursor) = ChildIndexing(unwrap(tc))


struct InitialState end


# this version assumes all we can do is call `children`… if even that is inefficient you're fucked
struct ImplicitCursor{P,N,S} <: TreeCursor{P,N}
    parent::P
    node::N
    sibling_state::S

    ImplicitCursor(p, n, s=InitialState()) = new{typeof(p),typeof(n),typeof(s)}(p, n, s)
end

unwrap(csr::ImplicitCursor) = csr.node

# parent must always be a properly initliazed ImplicitCursor
parent(csr::ImplicitCursor) = csr.parent

Base.IteratorSize(::Type{ImplicitCursor{P,N,S}}) where {P,N,S} = IteratorSize(childtype(N))

Base.length(csr::ImplicitCursor) = (length ∘ children ∘ unwrap)(csr)

Base.IteratorEltype(::Type{<:ImplicitCursor}) = HasEltype()

function Base.eltype(::Type{ImplicitCursor{P,N,S}}) where {P,N,S}
    cst = (childstatetype ∘ nodetype)(P)
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

    IndexedCursor(p, n, idx::Integer=1) = new{typeof(p),typeof(n)}(p, n, idx)
end

IndexedCursor(::ImplicitParents, n) = IndexedCursor(nothing, n)
IndexedCursor(::StoredParents, n) = IndexedCursor(IndexedCursor(parent(n)), n)
IndexedCursor(n) = IndexedCursor(parentlinks(n), n)

unwrap(csr::IndexedCursor) = csr.node

parent(csr::IndexedCursor) = csr.parent

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


#====================================================================================================
TODO:

There are lots of other cases that we just haven't implemented yet, and they are probably rare
- SiblingCursor: a type provides `nextsibling` and `prevsibling` so that siblings can be iterated
    more efficiently.  Need 2 versions for indexing.
====================================================================================================#

TreeCursor(::NonIndexedChildren, node) = ImplicitCursor(nothing, node)
TreeCursor(::IndexedChildren, node) = IndexedCursor(nothing, node)
TreeCursor(node) = TreeCursor(ChildIndexing(node), node)
