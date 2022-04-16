
abstract type TreeCursor end

#TODO: these are probably good enough for now, look at the iteration and indexing methods to see
#what else might be desirable

#TODO: NodeCompletion was for cases where you can only call children(tree, node) so will need to
#worry about that

#TODO: what do we want to do about indexing?  there is already a trait do we really want to have a
#wrapper?


# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor}) = SizeUnknown()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc


struct InitialState end


# this version assumes all we can do is call `children`… if even that is inefficient you're fucked
struct ImplicitCursor{P,N,SS,PS,PSS} <: TreeCursor
    parent::Union{Nothing,P}
    node::N
    sibling_state::SS
    prev_sibling::Union{Nothing,PS}  # must be cursor
    prev_sibling_state::PSS
end

ImplicitCursor(node) = ImplicitCursor(nothing, node, InitialState(), nothing, nothing)

getnode(csr::ImplicitCursor) = csr.node

# parent must always be a properly initliazed ImplicitCursor
parent(csr::ImplicitCursor) = csr.parent

function Base.iterate(csr::ImplicitCursor, (c, s)=(nothing, InitialState()))
    cs = (children ∘ getnode)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = s isa InitialState ? iterate(cs) : iterate(cs, s)
    isnothing(r) && return nothing
    (n′, s′) = r
    (ImplicitCursor(csr, n′, s′, c, s), (n′, s′))
end

function nextsibling(csr::ImplicitCursor)
    cs = (children ∘ getnode ∘ parent)(csr)
    # do NOT just write an iterate(x, ::InitialState) method, it's an ambiguity nightmare
    r = csr.sibling_state isa InitialState ? iterate(cs) : iterate(cs, csr.sibling_state)
    isnothing(r) && return nothing
    (n′, s′) = r
    ImplicitCursor(parent(csr), n′, s′, getnode(csr), csr.sibling_state)
end

prevsibling(csr::ImplicitCursor) = csr.prev_sibling


function SiblingCursor{P,N}
    parent::Union{Nothing,P}
    node::N
end

getnode(csr::SiblingCursor) = csr.node

# parent must always be a properly initialized SiblingCursor
parent(csr::SiblingCursor) = csr.parent

function Base.iterate(csr::SiblingCursor, (c, s)=(nothing, InitialState()))
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
