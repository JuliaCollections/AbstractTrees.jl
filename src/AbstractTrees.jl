module AbstractTrees

export print_tree, TreeCharSet, TreeIterator, Leaves, PostOrderDFS, Tree,
    AnnotationNode, StatelessBFS, treemap, treemap!, PreOrderDFS,
    ShadowTree, children

import Base: getindex, setindex!, iterate, nextind, print, show,
    eltype, IteratorSize, IteratorEltype, length, push!, pop!
using Base: SizeUnknown, EltypeUnknown
using Markdown

abstract type AbstractShadowTree end

include("traits.jl")
include("implicitstacks.jl")

# This package is intended to provide an abstract interface for working
# with tree structures.
# Though the package itself is not particularly sophisticated, it defines
# the interface that can be used by other packages to talk about trees.

"""
    children(x)

Return the immediate children of node `x`. You should specialize this method
for custom tree structures. It should return an iterable object for which an
appropriate implementation of `Base.pairs` is available.

# Example

```
struct MyNode{T}
    data::T
    children::Vector{MyNode{T}}
end
AbstractTrees.children(node::MyNode) = node.children
```
"""
function children(x)
    # By default assume that if an object is iterable, its iteration gives the
    # children. If an object is not iterable, assume it does not have children by
    # default.
    if Base.isiterable(typeof(x)) && !isa(x, Integer) && !isa(x, Char) && !isa(x, Task)
        return x
    else
        return ()
    end
end
has_children(x) = children(x) !== ()

"""
    printnode(io::IO, node)

Print a single node. The default is to show a compact representation of `node`.
Override this if you want nodes printed in a custom way in [`print_tree`](@ref),
or if you want your print function to print part of the tree by default.

# Example

```
struct MyNode{T}
    data::T
    children::Vector{MyNode{T}}
end
AbstractTrees.printnode(io::IO, node::MyNode) = print(io, "MyNode(\$(node.data))")
```
"""
printnode(io::IO, node) = show(IOContext(io, :compact => true), node)

## Special cases

# Don't consider strings or reals tree-iterable in general
children(x::AbstractString) = ()
children(x::Real) = ()

# Define this here, there isn't really a good canonical package to define this
# elsewhere
children(x::Expr) = x.args

# For AbstractDicts

printnode(io::IO, kv::Pair{K,V}) where {K,V} = printnode(io,kv[1])
children(kv::Pair{K,V}) where {K,V} = (kv[2],)

# For potentially-large containers, just show the type

printnode(io::IO, d::Dict{K,V}) where {K,V} = print(io, Dict{K,V})
printnode(io::IO, d::Vector{T}) where {T} = print(io, Vector{T})

# Node equality predicate
nodeequal(a, b) = a === b

# Utilities

# Printing
struct TreeCharSet
    mid
    terminator
    skip
    dash
end

# Default charset
TreeCharSet() = TreeCharSet('├','└','│','─')

function print_prefix(io, depth, charset, active_levels)
    for current_depth in 0:(depth-1)
        if current_depth in active_levels
            print(io,charset.skip," "^(textwidth(charset.dash)+1))
        else
            print(io," "^(textwidth(charset.skip)+textwidth(charset.dash)+1))
        end
    end
end

function _print_tree(printnode::Function, io::IO, tree, maxdepth = 5; depth = 0, active_levels = Int[],
                     charset = TreeCharSet(), withinds = false, inds = [], from = nothing, to = nothing, roottree = tree)
    nodebuf = IOBuffer()
    isa(io, IOContext) && (nodebuf = IOContext(nodebuf, io))
    if withinds
        printnode(nodebuf, tree, inds)
    else
        tree != roottree && isa(treekind(roottree), IndexedTree) ?
            printnode(nodebuf, roottree[tree]) :
            printnode(nodebuf, tree)
    end
    str = String(take!(isa(nodebuf, IOContext) ? nodebuf.io : nodebuf))
    for (i,line) in enumerate(split(str, '\n'))
        i != 1 && print_prefix(io, depth, charset, active_levels)
        println(io, line)
    end
    c = isa(treekind(roottree), IndexedTree) ?
        childindices(roottree, tree) : children(roottree, tree)
    if c !== ()
        s = Iterators.Stateful(from === nothing ? pairs(c) : Iterators.Rest(pairs(c), from))
        while !isempty(s)
            ind, child = popfirst!(s)
            ind === to && break
            active = false
            child_active_levels = active_levels
            print_prefix(io, depth, charset, active_levels)
            if isempty(s)
                print(io, charset.terminator)
            else
                print(io, charset.mid)
                child_active_levels = push!(copy(active_levels), depth)
            end
            print(io, charset.dash, ' ')
            print_tree(printnode, io, child; depth = depth + 1,
              active_levels = child_active_levels, charset = charset, withinds=withinds,
              inds = withinds ? [inds; ind] : [], roottree = roottree)
        end
    end
end
print_tree(f::Function, io::IO, tree, args...; kwargs...) = _print_tree(f, io, tree, args...; kwargs...)
print_tree(io::IO, tree, args...; kwargs...) = print_tree(printnode, io, tree, args...; kwargs...)
print_tree(tree, args...; kwargs...) = print_tree(stdout::IO, tree, args...; kwargs...)

"""
    print_tree(tree, maxdepth=5; kwargs...)
    print_tree(io, tree, maxdepth=5; kwargs...)
    print_tree(f::Function, io, tree, maxdepth=5; kwargs...)

# Usage
Prints an ASCII formatted representation of the `tree` to the given `io` object.
By default all children will be printed up to a maximum level of 5, though this
value can be overriden by the `maxdepth` parameter. The charset to use in
printing can be customized using the `charset` keyword argument.
You can control the printing of individual nodes by passing a function `f(io, node)`;
the default is [`AbstractTrees.printnode`](@ref).

# Examples
```julia
julia> print_tree(STDOUT,Dict("a"=>"b","b"=>['c','d']))
Dict{String,Any}("b"=>['c','d'],"a"=>"b")
├─ b
│  ├─ c
│  └─ d
└─ a
   └─ b

julia> print_tree(STDOUT,Dict("a"=>"b","b"=>['c','d']);
        charset = TreeCharSet('+','\\','|',"--"))
Dict{String,Any}("b"=>['c','d'],"a"=>"b")
+-- b
|   +-- c
|   \\-- d
\\-- a
   \\-- b
```

"""
print_tree

# Tree Indexing
struct Tree
    x::Any
end
Tree(x::Tree) = x
Tree(x::AbstractShadowTree) = x
show(io::IO, tree::Tree) = print_tree(io, tree.x)

mutable struct AnnotationNode{T}
    val::T
    children::Vector{AnnotationNode{T}}
end

children(x::AnnotationNode) = x.children
printnode(io::IO, x::AnnotationNode) = print(io, x.val)

struct ShadowTree <: AbstractShadowTree
    tree::Tree
    shadow::Tree
    ShadowTree(x::Tree,y::Tree) = new(x,y)
    ShadowTree(x,y) = ShadowTree(Tree(x),Tree(y))
end
first_tree(x::ShadowTree) = x.tree
second_tree(x::ShadowTree) = x.shadow

function zip_min(c1, c2)
    n1, n2 = length(c1), length(c2)
    if n1 < n2
        c2 = Iterators.take(c2,n1)
    elseif n2 < n1
        c1 = Iterators.take(c1,n2)
    end
    zip(c1, c2)
end

make_zip(x::AbstractShadowTree) = zip_min(children(x.tree.x), children(x.shadow.x))

function children(x::AbstractShadowTree)
    map(res->typeof(x)(res[1], res[2]),make_zip(x))
end

iterate(x::AbstractShadowTree, state...) = iterate(make_zip(x), state...)

function make_annotations(cb, tree, parent, s)
    s = cb(tree, parent, s)
    AnnotationNode{Any}(s, AnnotationNode{Any}[make_annotations(cb, child, tree, s) for child in children(tree)])
end

function getindex(tree::Tree, indices)
    node = tree.x
    for idx in indices
        node = children(node)[idx]
    end
    node
end
getindex(tree::Tree, indices::T) where {T<:ImplicitNodeStack} =
    getindex(tree, indices.idx_stack.stack)


function getindexhighest(tree::Tree, indices)
    node = tree.x
    for (i,idx) in enumerate(indices)
        cs = children(node)
        if idx > length(cs)
            return (indices[1:i-1],node)
        end
        node = children(node)[idx]
    end
    (indices, node)
end

function setindex!(tree::Tree, val, indices)
    setindex!(children(getindex(tree,indices[1:end-1])),val,indices[end])
end
setindex!(tree::Tree, val, indices::T) where {T<:ImplicitNodeStack} =
    setindex!(tree, val, indices.idx_stack.stack)

function getindex(tree::AbstractShadowTree, indices)
    typeof(tree)(Tree(first_tree(tree))[indices],Tree(second_tree(tree))[indices])
end

function setindex!(tree::AbstractShadowTree, val, indices)
    setindex!(Tree(first_tree(tree)), first_tree(val), indices)
    setindex!(Tree(second_tree(tree)), second_tree(val), indices)
end

function setindex!(tree::AbstractShadowTree, val::Tuple, indices)
    setindex!(Tree(first_tree(tree)), val[1], indices)
    setindex!(Tree(second_tree(tree)), val[2], indices)
end

# Tree Iterators

abstract type TreeIterator{T} end
IteratorEltype(::Type{<:TreeIterator}) = EltypeUnknown()

"""
Iterator to visit the leaves of a tree, e.g. for the tree

Any[1,Any[2,3]]
├─ 1
└─ Any[2,3]
   ├─ 2
   └─ 3

we will get [1,2,3]
"""
struct Leaves{T} <: TreeIterator{T}
    tree::T
end
IteratorSize(::Type{Leaves{T}}) where {T} = SizeUnknown()

"""
Iterator to visit the nodes of a tree, guaranteeing that children
will be visited before their parents.

e.g. for the tree

Any[1,Any[2,3]]
├─ 1
└─ Any[2,3]
   ├─ 2
   └─ 3

we will get [1,2,3,Any[2,3],Any[1,Any[2,3]]]
"""
struct PostOrderDFS <: TreeIterator{Any}
    tree::Any
    PostOrderDFS(x::Any) = new(x)
end
PostOrderDFS(tree::Tree) = PostOrderDFS(tree.x)
IteratorSize(::Type{PostOrderDFS}) = SizeUnknown()

"""
Iterator to visit the nodes of a tree, guaranteeing that parents
will be visited before their children.

Optionally takes a filter function that determines whether the iterator
should continue iterating over a node's children (if it has any) or should
consider that node a leaf.

e.g. for the tree

Any[Any[1,2],Any[3,4]]
├─ Any[1,2]
|  ├─ 1
|  └─ 2
└─ Any[3,4]
   ├─ 3
   └─ 4

we will get [Any[Any[1,2],Any[3,4]],Any[1,2],1,2,Any[3,4],3,4]

# Invalidation
Modifying the underlying tree while iterating over it, is allowed, however,
if parents and sibling links are not explicitly stored, the identify of any
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

# State depends on what kind of tree we have:
#   - Parents/Siblings are not stored:
#       - RegularTree: ImplicitNodeStack
#       - IndexedTree: ImplicitIndexStack
#   - Parents/Siblings are stored:
#       - RegularTree: Nodes
#       - IndexedTree: Indices
#
childstates(tree, state, ::IndexedTree) = childindices(tree, state)
childstates(tree, state, ::RegularTree) = children(tree, state)
parentstate(tree, state, ::IndexedTree) = parentind(tree, state)
parentstate(tree, state, ::RegularTree) = parent(tree, state)

parentstate(tree, state) = parentstate(tree, state, treekind(tree))

update_state!(old_state, cs, idx) = next(cs, idx)[1]


getindex(x::AbstractArray, ::ImplicitRootState) = x

function firststate(ti::PreOrderDFS{T}) where T
    if isa(parentlinks(ti.tree), StoredParents) &&
            isa(siblinglinks(ti.tree), SiblingLinks)
        rootstate(ti.tree)
    else
        state = ImplicitIndexStack(idxtype(ti.tree)[])
        if !isa(treekind(typeof(ti.tree)), IndexedTree)
            state = ImplicitNodeStack(nodetype(ti.tree)[], state)
        end
        state
    end
end
function firststate(ti::Union{Leaves, PostOrderDFS})
    state = firststate(PreOrderDFS(ti.tree))
    while true
        css = childstates(ti.tree, state)
        isempty(css) && break
        state = first(css)
    end
    state
end

nextind(::Base.Generator, idx) = idx + 1
relative_state(tree, parentstate, childstate::ImplicitIndexStack) =
    childstate.stack[end]
relative_state(tree, parentstate, childstate::ImplicitNodeStack) =
    relative_state(tree, parentstate, childstate.idx_stack)

function nextsibling(tree, state)
    ps = parentstate(tree, state)
    cs = childstates(tree, ps)
    isempty(cs) && return nothing
    new_state = nextind(cs, relative_state(tree, ps, state))
    iterate(cs, new_state) === nothing && return nothing
    update_state!(tree, ps, children(tree, ps), new_state)
end

function nextsibling(node, ::StoredParents, ::ImplicitSiblings, ::RegularTree)
    isroot(node) && return nothing
    p = parent(node)
    last_was_node = false
    for c in children(p)
        last_was_node && return c
        (c == node) && (last_was_node = true)
    end
    last_was_node && return nothing
    error("Tree inconsistency: node not a child of parent")
end
nextsibling(node, ::Any, ::StoredSiblings, ::Any) = error("Trees with explicit siblings must override the `nextsibling` method explicitly")
nextsibling(node) = nextsibling(node, parentlinks(node), siblinglinks(node), treekind(node))

function prevsibling(node, ::StoredParents, ::ImplicitSiblings, ::RegularTree)
    isroot(node) && return nothing
    p = parent(node)
    last_c = nothing
    for c in children(p)
        (c == node) && return last_c
        last_c = c
    end
    @show p
    @show node
    error("Tree inconsistency: node not a child of parent")
end
prevsibling(node, ::Any, ::StoredSiblings, ::Any) = error("Trees with explicit siblings must override the `prevsibling` method explicitly")
prevsibling(node) = prevsibling(node, parentlinks(node), siblinglinks(node), treekind(node))
prevsibling(tree, node) = prevsibling(node)

isroot(tree, state, ::RegularTree) = tree == state
isroot(tree, state, ::IndexedTree) = state == rootstate(tree)
isroot(tree, state) = isroot(tree, state, treekind(tree))

struct Subtree{T,S}
    tree::T
    state::S
end
children(tree::Subtree) = children(tree.tree, tree.state)
nodetype(tree::Subtree) = nodetype(tree.tree)
idxtype(tree::Subtree) = idxtype(tree.tree)
rootstate(tree::Subtree) = tree.state
parentlinks(::Type{Subtree{T,S}}) where {T,S} = parentlinks(T)

joinstate(tree, a, b) = b

if isdefined(Base, :UnionAll)
    Base.@pure function get_primary(T::DataType)
        T.name.wrapper
    end
else
    Base.@pure function get_primary(T::DataType)
        T.name.primary
    end
end

function stepstate(ti::TreeIterator, state)
    if isa(ti, PreOrderDFS) && ti.filter(getnode(ti.tree, state))
        ccs = childstates(ti.tree, state)
        !isempty(ccs) && return first(ccs)
    end
    while !isroot(ti.tree, state)
        nextstate = nextsibling(ti.tree, state)
        if nextstate !== nothing
            return joinstate(ti.tree, nextstate, firststate(
                get_primary(typeof(ti))(Subtree(ti.tree, nextstate))))
        end
        state = parentstate(ti.tree, state)
        isa(ti, PostOrderDFS) && return state
    end
    nothing
end

getnode(tree::AbstractShadowTree, ns::ImplicitNodeStack) = tree[ns.idx_stack.stack]
getnode(tree, ns) = getnode(tree, ns, treekind(tree))
getnode(tree, ns, ::IndexedTree) = tree[ns]
getnode(tree, ns, ::RegularTree) = ns
getnode(tree, ::ImplicitRootState, ::RegularTree) = tree

function iterate(ti::TreeIterator)
    state = firststate(ti)
    (getnode(ti.tree, state), state)
end
function iterate(ti::TreeIterator, state)
    state = stepstate(ti, state)
    state === nothing && return nothing
    (getnode(ti.tree, state), state)
end

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
Iterator to visit the nodes of a tree, all nodes of a level will be visited
before their children

e.g. for the tree

Any[1,Any[2,3]]
├─ 1
└─ Any[2,3]
   ├─ 2
   └─ 3

we will get [Any[1,Any[2,3]],1,Any[2,3],2,3]

WARNING: This is O(n^2), only use this if you know you need it, as opposed to
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
    state = firststate(ti)
    while state !== nothing
        ind = state
        node = getnode(ti.tree, ind)
        new_node = f(node)
        if new_node !== node
            if isempty(ind)
                return treemap!(PreOrderDFS(new_node)) do x
                    x == new_node && return x
                    f(x)
                end
            end
            Tree(ti.tree)[ind] = new_node
        end
        state = stepstate(ti, ind)
    end
    ti.tree
end

end # module
