

abstract type IteratorState{T<:TreeCursor} end

# we define this explicitly to avoid run-time dispatch
function instance(::Type{S}, node; kw...) where {S<:IteratorState} 
    isnothing(node) ? nothing : S(node; kw...)
end


abstract type TreeIterator{T} end

Base.IteratorSize(::Type{<:TreeIterator}) = SizeUnknown()

function Base.iterate(ti::TreeIterator, s::Union{Nothing,IteratorState}=initial(statetype(ti), ti.root))
    isnothing(s) && return nothing
    (unwrap(s.cursor), next(s))
end


#TODO: this needs to implement filtering
# only put that in the iterator, can take as an argument to `next`

struct PreOrderState{T<:TreeCursor} <: IteratorState{T}
    cursor::T
end

initial(::Type{PreOrderState}, node) = (PreOrderState ∘ TreeCursor)(node)

function next(s::PreOrderState)
    # root gets special handling
    ch = children(s.cursor)
    isempty(ch) || return instance(PreOrderState, first(ch))

    csr = s.cursor
    while !isroot(csr)
        n = nextsibling(csr)
        if isnothing(n)
            csr = parent(csr)
        else
            return PreOrderState(n)
        end
    end
    nothing
end


struct PreOrderDFS{T} <: TreeIterator{T}
    root::T
end

statetype(itr::PreOrderDFS) = PreOrderState


struct PostOrderState{T<:TreeCursor} <: IteratorState{T}
    cursor::T
end

initial(::Type{PostOrderState}, node) = (PostOrderState ∘ descendleft ∘ TreeCursor)(node)

function next(s::PostOrderState)
    n = nextsibling(s.cursor)
    if isnothing(n)
        instance(PostOrderState, parent(s.cursor))
    else
        # descendleft is not allowed to return nothing
        PostOrderState(descendleft(n))
    end
end


struct PostOrderDFS{T} <: TreeIterator{T}
    root::T
end

statetype(itr::PostOrderDFS) = PostOrderState


struct LeavesState{T<:TreeCursor} <: IteratorState{T}
    cursor::T
end

initial(::Type{LeavesState}, node) = (LeavesState ∘ descendleft ∘ TreeCursor)(node)

function next(s::LeavesState)
    csr = s.cursor
    while !isnothing(csr) && !isroot(csr)
        n = nextsibling(csr)
        if isnothing(n)
            csr = parent(csr)
        else
            # descendleft is not allowed to return nothing
            return LeavesState(descendleft(n))
        end
    end
    nothing
end


struct Leaves{T} <: TreeIterator{T}
    root::T
end

statetype(itr::Leaves) = LeavesState
