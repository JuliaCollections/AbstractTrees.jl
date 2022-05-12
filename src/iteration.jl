

abstract type IteratorState{T<:TreeCursor} end

# we define this explicitly to avoid run-time dispatch
function instance(::Type{S}, node; kw...) where {S<:IteratorState}
    isnothing(node) ? nothing : S(node; kw...)
end


abstract type TreeIterator{T} end

#====================================================================================================
This is pretty confusing and deserves some explanation...

Yes, we were careful enough with tree cursors that it seems like this should be HasEltype, but
the HasEltype() trait tells Julia not to try to narrow the eltype when using `collect`.
Therefore, if you have e.g. Any[1,[2,3]], the "correct" eltype that would be given if we used
HasEltype would be Any, but that's not really what we want.  Therefore we use EltypeUnknown here
even if that is worse on the (very special case) of a fully-known node type.
====================================================================================================#
Base.IteratorEltype(::Type{<:TreeIterator}) = EltypeUnknown()

Base.IteratorSize(::Type{<:TreeIterator}) = SizeUnknown()

function Base.iterate(ti::TreeIterator, s::Union{Nothing,IteratorState}=initial(statetype(ti), ti.root))
    isnothing(s) && return nothing
    (unwrap(s.cursor), next(s))
end


struct PreOrderState{T<:TreeCursor} <: IteratorState{T}
    cursor::T

    PreOrderState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

PreOrderState(node) = (PreOrderState ∘ TreeCursor)(node)

initial(::Type{PreOrderState}, node) = PreOrderState(node)

function next(f, s::PreOrderState)
    if f(unwrap(s.cursor))
        ch = children(s.cursor)
        isempty(ch) || return instance(PreOrderState, first(ch))
    end

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
next(s::PreOrderState) = next(x -> true, s)


struct PreOrderDFS{T,F} <: TreeIterator{T}
    filter::F
    root::T
end

PreOrderDFS(root) = PreOrderDFS(x -> true, root)

statetype(itr::PreOrderDFS) = PreOrderState

function Base.iterate(ti::PreOrderDFS, s::Union{Nothing,IteratorState}=initial(statetype(ti), ti.root))
    isnothing(s) && return nothing
    (unwrap(s.cursor), next(ti.filter, s))
end


struct PostOrderState{T<:TreeCursor} <: IteratorState{T}
    cursor::T

    PostOrderState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

PostOrderState(node) = (PostOrderState ∘ TreeCursor)(node)

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

    LeavesState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

LeavesState(node) = (LeavesState ∘ TreeCursor)(node)

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


struct SiblingState{T<:TreeCursor} <: IteratorState{T}
    cursor::T

    SiblingState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

SiblingState(node) = (SiblingState ∘ TreeCursor)(node)

initial(::Type{SiblingState}, node) = SiblingState(node)

next(s::SiblingState) = nextsibling(s.cursor)


struct Siblings{T} <: TreeIterator{T}
    root::T
end

statetype(itr::Siblings) = SiblingState


function _ascend(getparent, select, node)
    isroot(node) && (select(node); return node)
    p = getparent(node)
    while select(node) && !isroot(node)
        node = p
        p = getparent(node)
    end
    node
end

"""
    ascend(select, node)
    ascend(select, tree, node)

Ascend a tree starting from node `node` and at each node choosing whether or not to terminate by calling
`select(n)` where `n` is the current node (`false` terminates).

For the two argument method, parents are obtained by calling `parent(tree, node)`, otherwise by calling
`parent(node)`.

Note that the parent is computed before `select` is executed, allowing modification to its argument
(as long as the tree structure is not altered).
"""
ascend(select, tree, node) = _ascend(n -> parent(tree, n), select, node)
ascend(select, node) = _ascend(parent, select, node)

"""
    descend(select, tree)

Descends the tree, at each node choosing the child given by select callback
or the current node if 0 is returned.

Requires tree nodes to have [`IndexedChildren`](@ref).
"""
function descend(select, ::IndexedChildren, tree)
    idx = select(tree)
    idx == 0 && return tree
    node = children(tree)[idx]
    while true
        idx = select(node)
        idx == 0 && return node
        node = children(node)[idx]
    end
end
descend(select, node) = descend(select, ChildIndexing(node), node)


"""
    StatelessBFS{T} <: TreeIterator{T}

Iterator to visit the nodes of a tree, all nodes of a level will be visited
before their children

e.g. for the tree

```
Any[1,Any[2,3]]
├─ 1
└─ Any[2,3]
   ├─ 2
   └─ 3
```

we will get `[[1, [2,3]], 1, [2, 3], 2, 3]`.

WARNING: This is \$O(n^2)\$, only use this if you know you need it, as opposed to
a more standard statefull approach.
"""
struct StatelessBFS{T} <: TreeIterator{T}
    root::T
end

Base.iterate(ti::StatelessBFS) = (ti.root, [])

function _descend_left(inds, next_node, lvl)
    while length(inds) ≠ lvl
        ch = children(next_node)
        isempty(ch) && break
        push!(inds, 1)
        next_node = first(ch)
    end
    inds
end

function _nextind_or_deadend(node, ind, lvl)
    current_lvl = active_lvl = length(ind)
    active_inds = copy(ind)
    # go up until there is a sibling to the right
    while current_lvl > 0
        active_inds = ind[1:(current_lvl-1)]
        parent = childindex(node, active_inds)
        cur_child = ind[current_lvl]
        ch = children(parent)
        ni = nextind(ch, cur_child)
        current_lvl -= 1
        if !isnothing(iterate(ch, ni))
            newinds = [active_inds; ni]
            next_node = ch[ni]
            return _descend_left(newinds, next_node, lvl)
        end
    end
    nothing
end

function Base.iterate(ti::StatelessBFS, ind)
    org_lvl = active_lvl = length(ind)
    newinds = ind
    while true
        newinds = _nextind_or_deadend(ti.root, newinds, active_lvl)
        if isnothing(newinds)
            active_lvl += 1
            active_lvl > org_lvl + 1 && return nothing
            newinds = _descend_left([], ti.root, active_lvl)
        end
        length(newinds) == active_lvl && break
    end
    (childindex(ti.root, newinds), newinds)
end


"""
    MapNode{T,C}

A node in a tree which is returned by [`treemap`](@ref).  It consists of a value which is hte result of the function
call and an array of the children, which are also of type `MapNode`.

Every `MapNode` is itself a tree with the [`IndexedChildren`](@ref) trait and therefore supports indexing via
[`childindex`](@ref).

Use [`AbstractTrees.unwrap`](@ref) or `mapnode.value` to obtain the wrapped value.
"""
struct MapNode{T,C}
    value::T
    children::Vector{C}

    function MapNode(𝒻, node)
        v = 𝒻(node)
        ch = map(c -> MapNode(𝒻, c), children(node))
        if isempty(ch)
            new{typeof(v),MapNode{Union{}}}(v, MapNode{Union{}}[])
        else
            new{typeof(v),eltype(ch)}(v, ch)
        end
    end
end

children(μ::MapNode) = μ.children

unwrap(μ::MapNode) = μ.value

ChildIndexing(::MapNode) = IndexedChildren()

function Base.show(io::IO, μ::MapNode)
    print(io, typeof(μ))
    print(io, "(", μ.value, ")")
end

Base.show(io::IO, ::MIME"text/plain", μ::MapNode) = print_tree(io, μ)


"""
    treemap(𝒻, node)

Apply the function `𝒻` to every node in the tree with root `node`.  `node` must satisfy the AbstractTrees interface.
Instead of returning the result of `𝒻(n)` directly the result will be a tree of [`MapNode`](@ref) objects isomorphic
to the original tree but with values equal to the corresponding `𝒻(n)`.

Note that in most common cases tree nodes are of a type which depends on their connectedness and the function
`𝒻` should take this into account.  For example the tree `[1, [2, 3]]` contains integer leaves but two
`Vector` nodes.  Therefore, the `𝒻` in `treemap(𝒻, [1, [2,3]])` must be a function that is valid for either
`Int` or `Vector`.  Alternatively, to only operate on leaves do `map(𝒻, Leaves(itr))`.

## Example
```julia
julia> t = [1, [2, 3]];

julia> 𝒻(x) = x isa AbstractArray ? nothing : x + 1;

julia> treemap(𝒻, t)
MapNode{Nothing, MapNode}(nothing)
├─ MapNode{Int64, MapNode{Union{}}}(2)
└─ MapNode{Nothing, MapNode{Int64, MapNode{Union{}}}}(nothing)
   ├─ MapNode{Int64, MapNode{Union{}}}(3)
   └─ MapNode{Int64, MapNode{Union{}}}(4)
```
"""
treemap(𝒻, node) = MapNode(𝒻, node)
