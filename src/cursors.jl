
abstract type TreeCursor end

#TODO: NodeCompletion was for cases where you can only call children(tree, node) so will need to
#worry about that

#TODO: *DON'T* do any more work here yet!
# will need to work on iteration.jl to try to figure out which cases are important to implement


# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor}) = SizeUnknown()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc

childindexing(tc::TreeCursor) = childindexing(unwrap(tc))


struct InitialState end


# this version assumes all we can do is call `children`… if even that is inefficient you're fucked
struct ImplicitCursor{P,N,SS,PS,PSS} <: TreeCursor
    parent::P
    node::N
    sibling_state::SS
    prev_sibling::PS
    prev_sibling_state::PSS
end

# can't do one argument version because types are underdetermined
ImplicitCursor(p, n, s=InitialState()) = ImplicitCursor(p, n, s, nothing, nothing)

childrentype(::Type{T}) where {T<:ImplicitCursor} = childrentype(T)

unwrap(csr::ImplicitCursor) = csr.node

# parent must always be a properly initliazed ImplicitCursor
parent(csr::ImplicitCursor) = csr.parent

Base.IteratorSize(::Type{<:ImplicitCursor{P,N}}) where {P,N} = Base.IteratorSize(childrentype(N))

# it's too hard to determine type information because of all the tracking of states
Base.IteratorEltype(::Type{<:ImplicitCursor}) = EltypeUnknown()
Base.eltype(csr::ImplicitCursor)  = ImplicitCursor

function Base.iterate(csr::ImplicitCursor, (c, s)=(nothing, InitialState()))
    cs = (children ∘ unwrap)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    o = ImplicitCursor(csr, n′, s′, c, s)
    (o, (o, s′))
end

function nextsibling(csr::ImplicitCursor)
    isroot(csr) && return nothing
    cs = (children ∘ unwrap ∘ parent)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = csr.sibling_state isa InitialState ? iterate(cs) : iterate(cs, csr.sibling_state)
    isnothing(r) && return nothing
    (n′, s′) = r
    ImplicitCursor(parent(csr), n′, s′, unwrap(csr), csr.sibling_state)
end

prevsibling(csr::ImplicitCursor) = csr.prev_sibling


struct IndexedCursor{P,N} <: TreeCursor
    parent::P
    node::N
    index::Int

    IndexedCursor(p, n, idx=1) = new{typeof(p),typeof(n)}(p, n, idx)
end

IndexedCursor(::ImplicitParents, n) = IndexedCursor(nothing, n)
IndexedCursor(::StoredParents, n) = IndexedCursor(IndexedCursor(parent(n)), n)
IndexedCursor(n) = IndexedCursor(parentlinks(n), n)

unwrap(csr::IndexedCursor) = csr.node

parent(csr::IndexedCursor) = csr.parent

Base.IteratorSize(::Type{<:IndexedCursor}) = HasLength()
Base.IteratorEltype(::Type{<:IndexedCursor}) = HasEltype()

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
There are lots of other cases that we just haven't implemented yet, and they are probably rare
- SiblingCursor: a type provides `nextsibling` and `prevsibling` so that siblings can be iterated
    more efficiently.  Need 2 versions for indexing.
====================================================================================================#


