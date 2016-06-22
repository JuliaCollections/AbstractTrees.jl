VERSION >= v"0.4.0-dev+6641" && __precompile__()
module AbstractTrees

export print_tree, TreeCharSet, Leaves, PostOrderDFS, indenumerate, Tree,
    AnnotationNode, StatelessBFS, IndEnumerate, treemap, treemap!, PreOrderDFS,
    ShadowTree, children, Leaves

import Base: getindex, setindex!, start, next, done, nextind, print, show,
    eltype, iteratorsize, length
using Base: SizeUnknown

abstract AbstractShadowTree

# This package is intended to provide an abstract interface for working.
# Though the package itself is not particularly sophisticated, it defines
# the interface that can be used by other packages to talk about trees.

# By default assume that if an object is iterable, it's iteration gives the
# children. If an object is not iterable, assume it does not have children by
# default.
function children(x)
    if applicable(start, x) && !isa(x, Integer) && !isa(x, Char) && !isa(x, Task)
        return x
    else
        return ()
    end
end
has_children(x) = children(x) !== ()

# Print a single node. Override this if you want your print function to print
# part of the tree by default
printnode(io::IO, node) = showcompact(io,node)

# Special cases

# Don't consider strings or reals tree-iterable in general
children(x::AbstractString) = ()
children(x::Real) = ()

# Define this here, there isn't really a good canonical package to define this
# elsewhere
children(x::Expr) = x.args

# To support iteration over associatives, define printnode on Tuples to return
# the first element. If this doesn't work well in practice it may be better to
# create a special iterator that `children` on `Associative` returns.
# Even better, iteration over associatives should return pairs.

printnode{K,V}(io::IO, kv::Pair{K,V}) = printnode(io,kv[1])
children{K,V}(kv::Pair{K,V}) = kv[2]

nextind(x::Tuple, i::Integer) = i+1

# Utilities

# Printing
immutable TreeCharSet
    mid
    terminator
    skip
    dash
end

# Default charset
TreeCharSet() = TreeCharSet('├','└','│','─')

_charwidth(c::Char) = charwidth(c)
_charwidth(s) = sum(map(charwidth,collect(s)))

function print_prefix(io, depth, charset, active_levels)
    for current_depth in 0:(depth-1)
        if current_depth in active_levels
            print(io,charset.skip," "^(_charwidth(charset.dash)+1))
        else
            print(io," "^(_charwidth(charset.skip)+_charwidth(charset.dash)+1))
        end
    end
end

"""
# Usage
Prints an ASCII formatted representation of the `tree` to the given `io` object.
By default all children will be printed up to a maximum level of 5, though this
valud can be overriden by the `maxdepth` parameter. The charset to use in
printing can be customized using the `charset` keyword argument.

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
|   \-- d
\-- a
   \-- b
```

"""
function _print_tree(printnode::Function, io::IO, tree, maxdepth = 5; depth = 0, active_levels = Int[],
    charset = TreeCharSet(), withinds = false, inds = [], from = nothing, to = nothing)
    nodebuf = IOBuffer()
    isa(io, IOContext) && (nodebuf = IOContext(nodebuf, io))
    if withinds
        printnode(nodebuf, tree, inds)
    else
        printnode(nodebuf, tree)
    end
    str = takebuf_string(isa(nodebuf, IOContext) ? nodebuf.io : nodebuf)
    for (i,line) in enumerate(split(str, '\n'))
        i != 1 && print_prefix(io, depth, charset, active_levels)
        println(io, line)
    end
    c = children(tree)
    if c !== ()
        i = from === nothing ? start(c) : from
        while !done(c,i) && (to === nothing || i !== to)
            oldi = i
            child, i = next(c,i)
            active = false
            child_active_levels = active_levels
            print_prefix(io, depth, charset, active_levels)
            if done(c,i)
                print(io, charset.terminator)
            else
                print(io, charset.mid)
                child_active_levels = push!(copy(active_levels), depth)
            end
            print(io, charset.dash, ' ')
            print_tree(printnode, io, child; depth = depth + 1,
              active_levels = child_active_levels, charset = charset, withinds=withinds,
              inds = withinds ? [inds; oldi] : [])
        end
    end
end
print_tree(f::Function, io::IO, tree, args...; kwargs...) = _print_tree(f, io, tree, args...; kwargs...)
print_tree(io::IO, tree, args...; kwargs...) = print_tree(printnode, io, tree, args...; kwargs...)

# Tree Indexing
immutable Tree
    x::Any
end
Tree(x::Tree) = x
Tree(x::AbstractShadowTree) = x
show(io::IO, tree::Tree) = print_tree(io, tree.x)

type AnnotationNode{T}
    val::T
    children::Array{AnnotationNode{T}}
end

children(x::AnnotationNode) = x.children
printnode(io::IO, x::AnnotationNode) = print(io, x.val)

immutable ShadowTree <: AbstractShadowTree
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
        c2 = take(c2,n1)
    elseif n2 < n1
        c1 = take(c1,n2)
    end
    zip(c1, c2)
end

make_zip(x::AbstractShadowTree) = zip_min(children(x.tree.x), children(x.shadow.x))

function children(x::AbstractShadowTree)
    map(res->typeof(x)(res[1], res[2]),make_zip(x))
end

start(x::AbstractShadowTree) = start(make_zip(x))
next(x::AbstractShadowTree, it) = next(make_zip(x), it)
done(x::AbstractShadowTree, it) = done(make_zip(x), it)

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


# Utitlity Iterator - Should probably be moved elsewhere
immutable IndEnumerate{I}
    itr::I
end
indenumerate(itr) = IndEnumerate(itr)

iteratorsize{I}(::Type{IndEnumerate{I}}) = iteratorsize(I)
length(e::IndEnumerate) = length(e.itr)
start(e::IndEnumerate) = start(e.itr)
function next(e::IndEnumerate, state)
    n = next(e.itr,state)
    (state, n[1]), n[2]
end
done(e::IndEnumerate, state) = done(e.itr, state)

eltype{I}(::Type{IndEnumerate{I}}) = Tuple{Any, eltype(I)}

# Tree Iterators

abstract TreeIterator

"""
Iterator to visit the leaves of a tree, e.g. for the tree

Any[1,Any[2,3]]
├─ 1
└─ Any[2,3]
   ├─ 2
   └─ 3

we will get [1,2,3]
"""
immutable Leaves <: TreeIterator
    tree::Any
end
iteratorsize(::Type{Leaves}) = SizeUnknown()

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
immutable PostOrderDFS <: TreeIterator
    tree::Any
    PostOrderDFS(x::Any) = new(x)
end
PostOrderDFS(tree::Tree) = PostOrderDFS(tree.x)
iteratorsize(::Type{PostOrderDFS}) = SizeUnknown()

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
"""
immutable PreOrderDFS <: TreeIterator
    tree::Any
    filter::Function
    PreOrderDFS(tree,filter::Function=(args...)->true) = new(tree,filter)
end
PreOrderDFS(tree::Tree,filter::Function=(args...)->true) = PreOrderDFS(tree.x,filter)
iteratorsize(::Type{PreOrderDFS}) = SizeUnknown()

function depthfirstinds(node)
    inds = []
    c = children(node)
    while !isempty(c)
        push!(inds,1)
        node = first(c)
        c = children(node)
    end
    inds
end

function nextind{T}(ti::TreeIterator, idxs::Array{T})
    tree = ti.tree
    if length(idxs) == 0
        return nothing
    elseif length(idxs) == 1
        c = children(tree)
        ind = nextind(c, idxs[1])
        if isa(ti, PostOrderDFS) && done(c, ind)
            return []
        end
        return start(ti, ind; c = c)
    end
    active_idxs = copy(idxs)
    node = Tree(tree)[active_idxs[1:end-1]]
    while node != tree
        ind = pop!(active_idxs)
        nodeleaves = typeof(ti)(node)
        ni = nextind(nodeleaves, [ind])
        if !done(nodeleaves, ni)
            return vcat(active_idxs, ni)
        end
        node = Tree(tree)[active_idxs[1:end-1]]
    end
    return nextind(ti, [idxs[1]])
end

function nextind{T}(ti::PreOrderDFS, idxs::Array{T})
    tree = ti.tree
    node = Tree(tree)[idxs]
    cs = children(node)
    if ti.filter(node) && !isempty(cs)
        return [idxs; start(cs)]
    end
    active_idxs = copy(idxs)
    while node !== tree
        node = Tree(tree)[active_idxs[1:end-1]]
        ind = pop!(active_idxs)
        cs = children(node)
        ni = nextind(cs, ind)
        if !done(cs, ni)
            return vcat(active_idxs, ni)
        end
    end
    return nothing
end

done(ti::TreeIterator, idxs::Void) = true
done(ti::TreeIterator, idxs::Array) = false
function done(leaves::Leaves, idxs::Array)
    idxs[1] > length(children(leaves.tree))
end

function start(ti::TreeIterator, ind=1; c = children(ti.tree))
    if isempty(c)
        return []
    elseif ind <= length(c)
        return [ind, depthfirstinds(c[ind])...]
    else
        return [ind]
    end
end

function next(ti::TreeIterator, idxs)
    (Tree(ti.tree)[idxs], nextind(ti, idxs))
end

start(ti::PreOrderDFS) = []

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
immutable StatelessBFS <: TreeIterator
    tree::Any
end
start(ti::StatelessBFS) = []
iteratorsize(::Type{StatelessBFS}) = SizeUnknown()

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
        if !done(children(parent), ni)
            newinds = [active_inds; ni]
            next_node = children(parent)[ni]
            return descend_left(newinds, next_node, level)
        end
    end
    return nothing
end

"""
Stateless level-order bfs iteration. The algorithm is as follows:

Go up. If there is a right neighbor, go right, then left until you reach the
same level. If you reach the root, go left until you reach the next level.
"""
function next(ti::StatelessBFS, ind)
    cur_node = Tree(ti.tree)[ind]
    org_level = active_level = length(ind)
    newinds = ind
    while true
        newinds = nextind_or_deadend(ti.tree, newinds, active_level)
        if newinds === nothing
            active_level += 1
            if active_level > org_level + 1
                return (cur_node,nothing)
            end
            newinds = descend_left([], ti.tree, active_level)
        end
        if length(newinds) == active_level
            break
        end
    end
    (cur_node,newinds)
end

done(ti::StatelessBFS, idxs::Void) = true
done(ti::StatelessBFS, idxs::Array) = false

# Mapping over trees
function treemap(f::Function, tree::PostOrderDFS)
    new_tree = Any[Union{}[]]
    current_length = 0
    for (ind, node) in indenumerate(tree)
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
    for (ind, node) in indenumerate(ti)
        new_node = f(node)
        if new_node !== node
            ind == Any[] && return new_node
            Tree(ti.tree)[ind] = new_node
        end
    end
    ti.tree
end

end # module
