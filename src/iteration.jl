
abstract type TreeIterator{T} end

Base.IteratorSize(::Type{<:TreeIterator}) = SizeUnknown()


struct PreOrderDFS{T} <: TreeIterator{T}
    root::T
end

#FIX: no no no, this isn't even the right protocol

function nextcursor(::PreOrderDFS, csr::TreeCursor)
    n = nextsibling(csr)
    isnothing(n) || return n
    ch = children(csr)
    isempty(ch) ? nothing : first(ch)
end

function Base.iterate(ti::PreOrderDFS, csr::Union{Nothing,TreeCursor}=TreeCursor(ti.root))
    isnothing(csr) && return nothing
    (unwrap(csr), nextcursor(ti, csr))
end
