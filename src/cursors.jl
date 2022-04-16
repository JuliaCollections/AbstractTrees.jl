
abstract type TreeCursor end

#TODO: NodeCompletion was for cases where you can only call children(tree, node) so will need to
#worry about that

#TODO: what do we want to do about indexing?


# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor}) = SizeUnknown()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc

childindexing(tc::TreeCursor) = childindexing(getnode(tc))

_iteratorsize(::IndexedChildren) = HasLength()
_iteratorsize(::NonIndexedChildren) = SizeUnknown()
Base.IteratorSize(::Type{T}) where {T<:TreeCursor} = _iteratorsize(childindexing(T))

Base.iterate(tc::TreeCursor) = iterate(childindexing(tc), tc)
Base.iterate(tc::TreeCursor, s) = iterate(childindexing(tc), tc, s)

Base.getindex(tc::TreeCursor, idx) = getindeex(childindexing(tc), tc, idx)


struct InitialState end


#TODO: think I want to split this up depending on whether indexed

# this version assumes all we can do is call `children`… if even that is inefficient you're fucked
struct ImplicitCursor{P,N,SS,PS,PSS} <: TreeCursor
    parent::P
    node::N
    sibling_state::SS
    prev_sibling::PS
    prev_sibling_state::PSS
end

ImplicitCursor(p, n) = ImplicitCursor(p, n, InitialState(), nothing, nothing)
ImplicitCursor(n) = ImplicitCursor(nothing, n)

getnode(csr::ImplicitCursor) = csr.node

# parent must always be a properly initliazed ImplicitCursor
parent(csr::ImplicitCursor) = csr.parent

isroot(csr::ImplicitCursor) = isnothing(parent(csr))

Base.length(::IndexedChildren, csr::ImplicitCursor) = (length ∘ children ∘ getnode)(csr)
Base.length(csr::ImplicitCursor) = length(childindexing(csr), csr)

#===~~~~
It might seem weird that whether or not there is an eltype depends on indexing.
The problem is that without indexing iteration is so complicated it's too hard to
compute an eltype. With indexing it can be inferred based on eltype of nodes
~~~~~===#
Base.IteratorEltype(::NonIndexedChildren, csr::ImplicitCursor) = EltypeUnknown()
Base.IteratorEltype(::IndexedChildren, csr::ImplicitCursor) = Has
Base.IteratorEltype(csr::ImplicitCursor) = IteratorEltype(childindexing(csr), csr)

Base.eltype(::NonIndexedChildren, csr::ImplicitCursor) = ImplicitCursor
function Base.eltype(::IndexedChildren, csr::ImplicitCursor) 
    ImplicitCursor{typeof(csr),childtype(getnode(csr)),InitialState,Nothing,Nothing}
end

function Base.getindex(::IndexedChildren, csr::ImplicitCursor, idx)
    c = (children ∘ getnode)(csr)[idx]
    ImplicitCursor(csr, c)
end

function Base.iterate(::NonIndexedChildren, csr::ImplicitCursor, (c, s)=(nothing, InitialState()))
    cs = (children ∘ getnode)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = ImplicitCursor(csr, n′, s′, c, s)
    (o, (o, s′))
end
Base.iterate(::IndexedChildren, csr::ImplicitCursor, idx=1) = (csr[idx], idx+1)

#TODO: should we provide more efficient methods for indexed nextsibling?
function nextsibling(csr::ImplicitCursor)
    isroot(csr) && return nothing
    cs = (children ∘ getnode ∘ parent)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = csr.sibling_state isa InitialState ? iterate(cs) : iterate(cs, csr.sibling_state)
    isnothing(r) && return nothing
    (n′, s′) = r
    ImplicitCursor(parent(csr), n′, s′, getnode(csr), csr.sibling_state)
end

prevsibling(csr::ImplicitCursor) = csr.prev_sibling



struct SiblingCursor{P,N} <: TreeCursor
    parent::Union{Nothing,P}
    node::N
end

getnode(csr::SiblingCursor) = csr.node

# parent must always be a properly initialized SiblingCursor
parent(csr::SiblingCursor) = csr.parent

function Base.iterate(::NonIndexedChildren, csr::SiblingCursor, (c, s)=(nothing, InitialState()))
    cs = (children ∘ getnode)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    (SiblingCursor(csr, n′), (n′, s′))
end

function nextsibling(csr::SiblingCursor)
    ns = (nextsibling ∘ getnode)(csr)
    isnothing(ns) && return nothing
    SiblingCursor(parent(csr), ns)
end

function prevsibling(csr::SiblingCursor)
    ps = (prevsibling ∘ getnode)(csr)
    isnothing(ps) && return nothing
    SiblingCursor(parent(csr), ps)
end


# a parent cursor would only be different in that it doesn't have to start at the root


TreeCursor(::ImplicitParents, ::ImplicitSiblings, t) = ImplicitCursor(t)
TreeCursor(::ImplicitParents, ::StoredSiblings, t) = SiblingCursor(t)
TreeCursor(::StoredParents, ::ImplicitSiblings, t) = ParentCursor(t)
TreeCursor(::StoredParents, ::StoredSiblings, t) = t
TreeCursor(t) = TreeCursor(parentlinks(t), siblinglinks(t), t)
