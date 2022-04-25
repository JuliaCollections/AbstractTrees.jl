
abstract type TreeIterator{T} end

Base.IteratorSize(::Type{<:TreeIterator}) = SizeUnknown()


struct PreOrderDFS{T} <: TreeIterator{T}
    root::T
end

struct PreOrderState{T}
    cursor::T
    visited_children::Bool

    PreOrderState(csr::TreeCursor, vc::Bool=false) = new{typeof(csr)}(csr, vc)
end

function _firstchild(s::PreOrderState)
    ch = children(s.cursor)
    isempty(ch) ? nothing : PreOrderState(first(ch))
end

#TODO: this seems to be working but is very confusing, can it be cleaned up?
function next(s::PreOrderState)
    n = nextsibling(s.cursor)

    if isnothing(n)
        if s.visited_children
            p = parent(s.cursor)
            isnothing(p) ? nothing : next(PreOrderState(p, true))
        else
            o = _firstchild(s)
            p = parent(s.cursor)
            if isnothing(o)
                isnothing(p) ? nothing : next(PreOrderState(p, true))
            else
                o
            end
        end
    else
        if s.visited_children
            PreOrderState(n)
        else
            o = _firstchild(s)
            isnothing(o) ? PreOrderState(n) : o
        end
    end
end

function Base.iterate(ti::PreOrderDFS,
                      s::Union{Nothing,PreOrderState}=PreOrderState(TreeCursor(ti.root)),
                     )
    isnothing(s) && return nothing
    (unwrap(s.cursor), next(s))
end
