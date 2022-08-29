
"""
    InitialState

A type used for some AbstractTrees.jl iterators to indicate that iteration is in its initial state.
Typically this is used for wrapper types to indicate that the `iterate` function has not yet  been called
on the wrapped object.
"""
struct InitialState end


"""
    TreeCursor{N}

Abstract type for tree cursors which when constructed from a node can be used to
navigate the entire tree descended from that node.

Tree cursors satisfy the abstract tree interface with a few additional guarantees:
- Tree cursors all have the [`StoredParents`](@ref) and [`StoredSiblings`](@ref) traits.
- All functions acting on a cursor which returns a tree node is guaranteed to return another `TreeCursor`.
    For example, `children`, `parent` and `nextsibling` all return a `TreeCursor` of the same type as
    the argument.

Tree nodes which define `children` and have the traits [`StoredParents`](@ref) and
[`StoredSiblings`](@ref) satisfy the `TreeCursor` interface, but calling `TreeCursor(node)` on such
a node wraps them in a [`TrivialCursor`](@ref) to maintain a consistent interface.

## Constructors
All `TreeCursor`s possess (at least) the following constructors
- `T(node)`
- `T(parent, node)`

In the former case the `TreeCursor` is constructed for the tree of which `node` is the root.
"""
abstract type TreeCursor{N} end

"""
    nodevaluetype(csr::TreeCursor)

Get the type of the wrapped node.  This should match the return type of [`nodevalue`](@ref).
"""
nodevaluetype(::Type{<:TreeCursor{N}}) where {N} = N
nodevaluetype(csr::TreeCursor) = nodevaluetype(typeof(csr))

"""
    parenttype(csr::TreeCursor)

The return type of `parent(csr)`.  For properly constructed `TreeCursor`s this is guaranteed to be another
`TreeCursor`.
"""
parenttype(::Type{<:TreeCursor{N}}) where N = TreeCursor{N}
parenttype(csr::TreeCursor) = parenttype(typeof(csr))

# this is a fallback and may not always be the case
Base.IteratorSize(::Type{<:TreeCursor{N}}) where {N} = IteratorSize(childtype(N))

Base.length(tc::TreeCursor) = (length ∘ children ∘ nodevalue)(csr)

Base.IteratorEltype(::Type{<:TreeCursor}) = EltypeUnknown()

ParentLinks(::Type{<:TreeCursor}) = StoredParents()

SiblingLinks(::Type{<:TreeCursor}) = StoredSiblings()

# all TreeCursor give children on iteration
children(tc::TreeCursor) = tc

ChildIndexing(tc::TreeCursor) = ChildIndexing(nodevalue(tc))

nodevalue(tc::TreeCursor) = tc.node

parent(tc::TreeCursor) = tc.parent


"""
    TrivialCursor{N} <: TreeCursor{N}

A [`TreeCursor`](@ref) which matches the functionality of the underlying node.  Tree nodes wrapped by this
cursor themselves have most of the functionality required of a `TreeCursor`, this type exists entirely
for the sake of maintaining a fully consistent interface with other `TreeCursor` objects.
"""
struct TrivialCursor{N} <: TreeCursor{N}
    node::N
end

TrivialCursor(parent, node) = TrivialCursor(node)

function parent(csr::TrivialCursor)
    p = parent(csr.node)
    isnothing(p) && return nothing
    return TrivialCursor(p)
end

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
    isnothing(n) ? nothing : TrivialCursor(n)
end

function prevsibling(csr::TrivialCursor)
    p = prevsibling(csr.node)
    isnothing(p) ? nothing : TrivialCursor(p)
end


"""
    ImplicitCursor{P,N,S} <: TreeCursor{P,N}

A [`TreeCursor`](@ref) which wraps nodes which cannot efficiently access either their parents or siblings directly.
This should be thought of as a "worst case scenario" tree cursor.  In particular, `ImplicitCursor`s store the
child iteration state of type `S` and for any of `ImplicitCursor`s method to be type-stable it must be possible
to infer the child iteration state type, see [`childstatetype`](@ref).
"""
struct ImplicitCursor{N,S} <: TreeCursor{N}
    parent::Union{ImplicitCursor, Nothing}
    node::N
    sibling_state::S

    function ImplicitCursor(p::Union{ImplicitCursor, Nothing}, node::N, s=InitialState()) where N
        return new{N, typeof(s)}(p, node, s)
    end
end

ImplicitCursor(node) = ImplicitCursor(nothing, node)

Base.IteratorEltype(::Type{<:ImplicitCursor}) = HasEltype()

function Base.eltype(::Type{ImplicitCursor{N,S}}) where {N,S}
    nt = nodetype(N)
    cst = (childstatetype ∘ nodevalueeltype)(ImplicitCursor{nt, S})
    ImplicitCursor{nt,cst}
end

function Base.eltype(csr::ImplicitCursor{N,S}) where {N,S}
    cst = (childstatetype ∘ parent ∘ nodevalue)(csr)
    ImplicitCursor{nodetype(N),cst}
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


"""
    IndexedCursor{N} <: TreeCursor{N}

A [`TreeCursor`](@ref) for tree nodes with the [`IndexedChildren`](@ref) trait but for which parents and siblings
are not directly accessible.

This type is very similar to [`ImplicitCursor`](@ref) except that it is free to assume that the child iteration
state is an integer starting at `1` which drastially simplifies type inference and slightly simplifies the
iteration methods.
"""
struct IndexedCursor{N} <: TreeCursor{N}
    parent::Union{IndexedCursor, Nothing}
    node::N
    index::Int

    IndexedCursor(p::Union{Nothing,IndexedCursor}, n, idx::Integer=1) = new{typeof(n)}(p, n, idx)
end

IndexedCursor(node) = IndexedCursor(nothing, node)

Base.IteratorSize(::Type{<:IndexedCursor}) = HasLength()

function Base.eltype(::Type{IndexedCursor{N}}) where {N}
    IndexedCursor{childtype(N)}
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


"""
    SiblingCursor{N} <: TreeCursor{N}

A [`TreeCursor`](@ref) for trees with the [`StoredSiblings`](@ref) trait.
"""
struct SiblingCursor{N} <: TreeCursor{N}
    parent::SiblingCursor
    node::N

    SiblingCursor(p::Union{Nothing,SiblingCursor}, n) = new{typeof(n)}(p, n)
end

SiblingCursor(node) = SiblingCursor(nothing, node)

Base.IteratorSize(::Type{SiblingCursor{N}}) where {N} = IteratorSize(childtype(N))

Base.IteratorEltype(::Type{<:SiblingCursor}) = HasEltype()

function Base.eltype(::Type{SiblingCursor{N}}) where {N}
    nt = nodetype(SiblingCursor{N})
    cst = (childstatetype ∘ nodevaluetype)(SiblingCursor{nt})
    SiblingCursor{childtype(N)}
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
    isnothing(n) ? nothing : SiblingCursor(parent(csr), n)
end

function prevsibling(csr::SiblingCursor)
    p = prevsibling(nodevalue(csr))
    isnothing(p) ? nothing : SiblingCursor(parent(csr), p)
end


TreeCursor(::ChildIndexing, ::StoredParents, ::StoredSiblings, node) = TrivialCursor(node)

TreeCursor(::ChildIndexing, ::ImplicitParents, ::StoredSiblings, node) = SiblingCursor(node)

TreeCursor(::NonIndexedChildren, ::ParentLinks, ::ImplicitSiblings, node) = ImplicitCursor(node)
TreeCursor(::IndexedChildren, ::ParentLinks, ::ImplicitSiblings, node) = IndexedCursor(node)

TreeCursor(node) = TreeCursor(ChildIndexing(node), ParentLinks(node), SiblingLinks(node), node)
