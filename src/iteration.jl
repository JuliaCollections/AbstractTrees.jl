# Utilities for tree traversal and iteration

"""
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
    tree::T
end
IteratorSize(::Type{Leaves{T}}) where {T} = SizeUnknown()

"""
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
    tree::T
end
PostOrderDFS(tree::Tree) = PostOrderDFS(tree.x)
IteratorSize(::Type{PostOrderDFS{T}}) where T = SizeUnknown()

"""
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

# Invalidation
Modifying the underlying tree while iterating over it, is allowed, however,
if parents and sibling links are not explicitly stored, the identity of any
parent of the last obtained node does not change (i.e. mutation is allowed,
replacing nodes is not).

"""
struct PreOrderDFS{T} <: TreeIterator{T}
    tree::T
    filter::Function
    PreOrderDFS{T}(tree,filter::Function=(args...)->true) where {T} = new{T}(tree,filter)
end
PreOrderDFS(tree::T,filter::Function=(args...)->true) where {T} = PreOrderDFS{T}(tree,filter)
PreOrderDFS(tree::Tree,filter::Function=(args...)->true) = PreOrderDFS(tree.x,filter)
IteratorSize(::Type{PreOrderDFS{T}}) where {T} = SizeUnknown()

function descend_left(cursor)
    ccs = children(cursor)
    isempty(ccs) && return cursor
    return descend_left(first(ccs))
end

function Base.iterate(ti::PreOrderDFS)
    cursor = TreeCursor(ti.tree)
    (getnode(cursor), cursor)
end

function Base.iterate(ti::Union{PostOrderDFS, Leaves})
    cursor = descend_left(TreeCursor(ti.tree))
    (getnode(cursor), cursor)
end

function Base.iterate(ti::TreeIterator, cursor)
    if isa(ti, PreOrderDFS) && ti.filter(getnode(cursor))
        ccs = children(cursor)
        if !isempty(ccs)
            cursor = first(ccs)
            return (getnode(cursor), cursor)
        end
    end
    while !isroot(cursor)
        nextcursor = nextsibling(cursor)
        if nextcursor !== nothing
            if isa(ti, Union{PostOrderDFS, Leaves})
                nextcursor = descend_left(nextcursor)
            end
            return (getnode(nextcursor), nextcursor)
        end
        cursor = parent(cursor)
        if isa(ti, PostOrderDFS)
            return (getnode(cursor), cursor)
        end
    end
    return nothing
end

getnode(tree) = tree
getnode(tree::LinkedTreeCursor) = tree.node

"""
    Acends the tree, at each node choosing whether or not to continue.
    Note that the parent is computed before the callback is exectuted, allowing
    modification of the argument to the callback (as long as the overall tree
    structure is not altered).
"""
function ascend(select, node)
    isroot(node) && (select(node); return node)
    p = parent(node)
    while select(node) && !isroot(node)
        node = p
        p = parent(node)
    end
    node
end

"""
    Descends the tree, at each node choosing the child given by select callback
    or the current node if 0 is returned.
"""
function descend(select, tree)
    idx = select(tree)
    idx == 0 && return tree
    node = children(tree)[idx]
    while true
        idx = select(node)
        idx == 0 && return node
        node = children(node)[idx]
    end
end

"""
    Base.searchsortedlast(leaves::Leaves, x; by=getnode)

Return the last leaf of `leaves` less than or equal to `x`. Assumes that leaves
are in sorted order and that non-leaf nodes sort equal to the smallest of their
children.
"""
function Base.searchsortedlast(leaves::Leaves, v; by=getnode)
    tree = leaves.tree
    if isless(v, by(tree))
        return nothing
    end
    while true
        cs = children(tree)
        isempty(cs) && return tree
        idx = searchsortedlast(cs, v; by=by)
        @assert idx !== 0
        tree = cs[idx]
    end
end
function Base.searchsortedlast(tree::TreeCursor, args...; kwargs...)
    searchsortedlast(getnode(tree), args...; kwargs...)
end

"""
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
struct StatelessBFS <: TreeIterator{Any}
    tree::Any
end
IteratorSize(::Type{StatelessBFS}) = SizeUnknown()

function descend_left(newinds, next_node, level)
    # Go down until we are at the correct level or a dead end
    while length(newinds) != level
        cs = children(next_node)
        if isempty(cs)
            break
        end
        push!(newinds, 1)
        next_node = first(cs)
    end
    return newinds
end

function nextind_or_deadend(tree, ind, level)
    current_level = active_level = length(ind)
    active_inds = copy(ind)
    # Go up until there is a right neighbor
    while current_level > 0
        # Check for next node at the current level
        active_inds = ind[1:current_level-1]
        parent = Tree(tree)[active_inds]
        cur_child = ind[current_level]
        ni = nextind(children(parent), cur_child)
        current_level -= 1
        if iterate(children(parent), ni) !== nothing
            newinds = [active_inds; ni]
            next_node = children(parent)[ni]
            return descend_left(newinds, next_node, level)
        end
    end
    return nothing
end

iterate(ti::StatelessBFS) = (Tree(ti.tree)[[]], [])
"""
Stateless level-order bfs iteration. The algorithm is as follows:

Go up. If there is a right neighbor, go right, then left until you reach the
same level. If you reach the root, go left until you reach the next level.
"""
function iterate(ti::StatelessBFS, ind)
    org_level = active_level = length(ind)
    newinds = ind
    while true
        newinds = nextind_or_deadend(ti.tree, newinds, active_level)
        if newinds === nothing
            active_level += 1
            if active_level > org_level + 1
                return nothing
            end
            newinds = descend_left([], ti.tree, active_level)
        end
        if length(newinds) == active_level
            break
        end
    end
    Tree(ti.tree)[newinds], newinds
end

# Mapping over trees
function treemap(f::Function, tree::PostOrderDFS)
    new_tree = Any[Union{}[]]
    current_length = 0
    for (ind, node) in pairs(tree)
        while length(new_tree) < length(ind)
            push!(new_tree, Union{}[])
        end
        thechildren = Union{}[]
        if length(ind) < length(new_tree)
            thechildren = pop!(new_tree)
        end
        if ind == []
            return f(ind, node, thechildren)
        end
        siblings = new_tree[end]
        el = f(ind, node, thechildren)
        S = typeof(el)
        T = eltype(siblings)
        if S === T || S <: T
            push!(siblings, el)
        else
            R = typejoin(T, S)
            new = similar(siblings, R)
            copy!(new,1,siblings,1,length(siblings))
            push!(new,el)
            new_tree[end] = new
        end
    end
end

function treemap!(f::Function, ti::PreOrderDFS)
    tree = ti.tree
    ti = PreOrderDFS(PairTree(nothing=>tree))
    r = iterate(ti)
    while r !== nothing
        ((idx, node), cursor) = r
        new_node = f(node)
        if new_node !== node
            if isroot(cursor)
                # Switch the entire tree
                tree = new_node
                ti = PreOrderDFS(PairTree(nothing=>new_node))
                r = iterate(ti)
                # But don't visit the root node again
                r === nothing && break
                r = iterate(ti, r[2])
                continue
            end
            pc = parent(cursor)
            getnode(pc)[2][idx] = new_node
            cursor = pc[idx]
        end
        r = iterate(ti, cursor)
    end
    tree
end
