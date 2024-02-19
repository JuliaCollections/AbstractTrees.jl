
"""
    IteratorState{T<:TreeCursor}

The state of a [`TreeIterator`](@ref) object.  These are simple wrappers of [`TreeCursor`](@ref) objects which define
a method for [`next`](@ref).  `TreeIterator`s are in turn simple wrappers of `IteratorState`s.

Each `IteratorState` fully determines the current iteration state and therefore the next state can be obtained
with `next` (`nothing` is returned after the final state is reached).
"""
abstract type IteratorState{T<:TreeCursor} end

# we define this explicitly to avoid run-time dispatch
"""
    instance(::Type{<:IteratorState}, node; kw...)

Create an instance of the given [`IteratorState`](@ref) around node `node`.  This is mostly just a constructor
for `IteratorState` except that if `node` is `nothing` it will return `nothing`.
"""
function instance(::Type{S}, node; kw...) where {S<:IteratorState}
    isnothing(node) ? nothing : S(node; kw...)
end

"""
    initial(::Type{<:IteratorState}, node)

Obtain the initial [`IteratorState`](@ref) of the provided type for the node `node`.
"""
function initial end

"""
    next(s::IteratorState)
    next(f, s::IteratorState)

Obtain the next [`IteratorState`](@ref) after the current one.  If `s` is the final state, this will return
`nothing`.

This provides an alternative iteration protocol which only uses the states directly as opposed to
[`Base.iterate`](@ref) which takes an iterator object and the current state as separate arguments.
"""
function next end

"""
    statetype(::Type{<:TreeIterator})

Gives the type of [`IteratorState`](@ref) which is the state of the provided [`TreeIterator`](@ref).
"""
function statetype end


"""
    TreeIterator{T}

An iterator of a tree that implements the AbstractTrees interface.  Every `TreeIterator` is simply a wrapper
of an [`IteratorState`](@ref) which fully determine the iteration state and implement their own alternative
protocol using [`next`](@ref).

## Constructors
All `TreeIterator`s have a one argument constructor `T(node)` which starts iteration from `node`.
"""
abstract type TreeIterator{T} end

_iterator_eltype(::NodeTypeUnknown) = EltypeUnknown()
_iterator_eltype(::HasNodeType) = HasEltype()

Base.IteratorEltype(::Type{<:TreeIterator{T}}) where {T}  = _iterator_eltype(NodeType(T))

Base.eltype(::Type{<:TreeIterator{T}}) where {T} = nodetype(T)
Base.eltype(ti::TreeIterator) = eltype(typeof(ti))

Base.IteratorSize(::Type{<:TreeIterator}) = SizeUnknown()

function Base.iterate(ti::TreeIterator, s=initial(statetype(ti), ti.root))
    isnothing(s) && return nothing
    (nodevalue(s.cursor), next(s))
end

"""
    nodevalues(itr::TreeIterator)

An iterator which returns the `nodevalue` of each node in the tree, equivalent to
`Iterators.map(nodevalue, itr)`.
"""
nodevalues(itr::TreeIterator) = Iterators.map(nodevalue, itr)

"""
    PreOrderState{T<:TreeCursor} <: IteratorState{T}

The iteration state of a tree iterator which guarantees that parent nodes will be visited *before* their children,
i.e. which descends a tree from root to leaves.

This state implements a [`next`](@ref) method which accepts a filter function as its first argument, allowing
tree branches to be skipped.

See [`PreOrderDFS`](@ref).
"""
struct PreOrderState{T<:TreeCursor} <: IteratorState{T}
    cursor::T

    PreOrderState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

PreOrderState(node) = PreOrderState(TreeCursor(node))

initial(::Type{PreOrderState}, node) = PreOrderState(node)

function next(f, s::PreOrderState)
    if f(nodevalue(s.cursor))
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
next(s::PreOrderState) = next(_ -> true, s)


"""
    PreOrderDFS{T,F} <: TreeIterator{T}

Iterator to visit the nodes of a tree, guaranteeing that parents
will be visited before their children.

Optionally takes a filter function that determines whether the iterator
should continue iterating over a node's children (if it has any) or should
consider that node a leaf.

e.g. for the tree
```
Any[Any[1,2],Any[3,4]]
├─ Any[1,2]
|  ├─ 1
|  └─ 2
└─ Any[3,4]
   ├─ 3
   └─ 4
```
we will get `[[[1, 2], [3, 4]], [1, 2], 1, 2, [3, 4], 3, 4]`.
"""
struct PreOrderDFS{T,F} <: TreeIterator{T}
    filter::F
    root::T
end

PreOrderDFS(root) = PreOrderDFS(_ -> true, root)

statetype(itr::PreOrderDFS) = PreOrderState

function Base.iterate(ti::PreOrderDFS, s::Union{Nothing,IteratorState}=initial(statetype(ti), ti.root))
    isnothing(s) && return nothing
    (nodevalue(s.cursor), next(ti.filter, s))
end


"""
    PostOrderState{T<:TreeCursor} <: IteratorState{T}

The state of a tree iterator which guarantees that parents are visited *after* their children, i.e. ascends
a tree from leaves to root.

See [`PostOrderDFS`](@ref).
"""
struct PostOrderState{T<:TreeCursor} <: IteratorState{T}
    cursor::T

    PostOrderState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

PostOrderState(node) = PostOrderState(TreeCursor(node))

initial(::Type{PostOrderState}, node) = PostOrderState(descendleft(TreeCursor(node)))

function next(s::PostOrderState)
    n = nextsibling(s.cursor)
    if isnothing(n)
        instance(PostOrderState, parent(s.cursor))
    else
        # descendleft is not allowed to return nothing
        PostOrderState(descendleft(n))
    end
end


"""
    PostOrderDFS{T} <: TreeIterator{T}

Iterator to visit the nodes of a tree, guaranteeing that children
will be visited before their parents.

e.g. for the tree
```
Any[1,Any[2,3]]
├─ 1
└─ Any[2,3]
   ├─ 2
   └─ 3
```
we will get `[1, 2, 3, [2, 3], [1, [2, 3]]]`.
"""
struct PostOrderDFS{T} <: TreeIterator{T}
    root::T
end

statetype(itr::PostOrderDFS) = PostOrderState


"""
    LeavesState{T<:TreeCursor} <: IteratorState{T}

A [`IteratorState`](@ref) of an iterator which visits the leaves of a tree.

See [`Leaves`](@ref).
"""
struct LeavesState{T<:TreeCursor} <: IteratorState{T}
    cursor::T

    LeavesState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

LeavesState(node) = LeavesState(TreeCursor(node))

initial(::Type{LeavesState}, node) = LeavesState(descendleft(TreeCursor(node)))

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


"""
    Leaves{T} <: TreeIterator{T}

Iterator to visit the leaves of a tree, e.g. for the tree
```
Any[1,Any[2,3]]
├─ 1
└─ Any[2,3]
   ├─ 2
   └─ 3
```
we will get `[1,2,3]`.
"""
struct Leaves{T} <: TreeIterator{T}
    root::T
end

statetype(itr::Leaves) = LeavesState


"""
    SiblingState{T<:TreeCursor} <: IteratorState{T}

A [`IteratorState`](@ref) of an iterator which visits all of the tree siblings after the current sibling.

See [`Siblings`](@ref).
"""
struct SiblingState{T<:TreeCursor} <: IteratorState{T}
    cursor::T

    SiblingState(csr::TreeCursor) = new{typeof(csr)}(csr)
end

SiblingState(node) = SiblingState(TreeCursor(node))

initial(::Type{SiblingState}, node) = SiblingState(node)

next(s::SiblingState) = nextsibling(s.cursor)


"""
    Siblings{T} <: TreeIterator{T}

A [`TreeIterator`](@ref) which visits the siblings of a node after the provided node.
"""
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

This iterator requires [`getdescendant`](@ref) to be valid for all nodes in the
tree, but the nodes do not necessarily need the [`IndexedChildren`](@ref) trait.

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
a more standard stateful approach.
"""
struct StatelessBFS{T} <: TreeIterator{T}
    root::T
end

Base.iterate(ti::StatelessBFS) = (ti.root, [])

function _descend_left(inds, next_node, level)
    while length(inds) ≠ level
        ch = children(next_node)
        isempty(ch) && break
        push!(inds, 1)
        next_node = first(ch)
    end
    inds
end

function _nextind_or_deadend(node, ind, level)
    current_lvl = active_lvl = length(ind)
    active_inds = ind
    # go up until there is a sibling to the right
    while current_lvl > 0
        active_inds = ind[1:(current_lvl-1)]
        parent = getdescendant(node, active_inds)
        cur_child = ind[current_lvl]
        ch = children(parent)
        ni = nextind(ch, cur_child)
        current_lvl -= 1
        if !isnothing(iterate(ch, ni))
            newinds = [active_inds; ni]
            next_node = ch[ni]
            return _descend_left(newinds, next_node, level)
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
    (getdescendant(ti.root, newinds), newinds)
end


"""
    MapNode{T,C}

A node in a tree which is returned by [`treemap`](@ref).  It consists of a value which is the result of the function
call and an array of the children, which are also of type `MapNode`.

Every `MapNode` is itself a tree with the [`IndexedChildren`](@ref) trait and therefore supports indexing via
[`getdescendant`](@ref).

Use [`AbstractTrees.nodevalue`](@ref) or `mapnode.value` to obtain the wrapped value.
"""
struct MapNode{T,C} <: AbstractNode{T}
    value::T
    children::C

    function MapNode(f, node)
        (v, ch) = f(node)
        ch′ = map(c -> MapNode(f, c), ch)
        new{typeof(v),typeof(ch′)}(v, ch′)
    end
end
MapNode(node) = MapNode(n -> (nodevalue(n), children(n)), nodevalue(node))

children(μ::MapNode) = μ.children

childrentype(::Type{MapNode{T,C}}) where {T,C} = C

nodevalue(μ::MapNode) = μ.value

ChildIndexing(::MapNode) = IndexedChildren()


"""
    treemap(f, node)

Apply the function `f` to every node in the tree with root `node`, where `f` is a function that returns `(v, ch)` where
`v` is a new value for the node (i.e. as returned by [`nodevalue`](@ref) and `ch` is the new children of the node.
`f` will be called recursively so that all the children returned by `f` for a parent node will again be called for
each child.  This means that to maintain the structure of a tree but merely map to new values, one should define
`f = node -> (g(node), children(node))` for some function `g` which returns a value for the node.

The nodes of the output tree will all be represented by [`MapNode`](@ref) objects wrapping the returned values.
This is necessary in order to guarantee that the output types can describe any tree topology.

Note that in most common cases tree nodes are of a type which depends on their connectedness and the function
`f` should take this into account.  For example the tree `[1, [2, 3]]` contains integer leaves but two
`Vector` nodes.  Therefore, the `f` in `treemap(f, [1, [2,3]])` must be a function that is valid for either
`Int` or `Vector`.  Alternatively, to only operate on leaves do `map(𝒻, Leaves(itr))`.

It's very easy to write an `f` that makes `treemap` stack-overflow.  To avoid this, ensure that `f` eventually
terminates, i.e. that sometimes it returns empty `children`.  For example, if `f(n) = (nothing, [0; children(n)])` will
stack-overflow because every node will have at least 1 child.

To create a tree with [`HasNodeType`](@ref) which enables efficient iteration, see [`StableNode`](@ref) instead.

## Examples
```julia
julia> t = [1, [2, 3]];

julia> f(n) = n isa AbstractArray ? (nothing, children(n)) : (n+1, children(n))

julia> treemap(f, t)
nothing
├─ 2
└─ nothing
   ├─ 3
   └─ 4

julia> g(n) = isempty(children(n)) ? (nodevalue(n), []) : (nodevalue(n), [0; children(n)])
g (generic function with 1 method)

julia> treemap(g, t)
Any[1, [2, 3]]
├─ 0
├─ 1
└─ [2, 3]
   ├─ 0
   ├─ 2
   └─ 3
```
"""
treemap(f, node) = MapNode(f, node)

