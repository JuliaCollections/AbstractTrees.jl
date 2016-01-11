module AbstractTrees

export print_tree, TreeCharSet, Leaves, PostOrderDFS, indenumerate, Tree,
    AnnotationNode

import Base: getindex, setindex!, start, next, done, nextind, print, show

# This package is intended to provide an abstract interface for working.
# Though the package itself is not particularly sophisticated, it defines
# the interface that can be used by other packages to talk about trees.

# By default assume that if an object is iterable, it's iteration gives the
# children. If an object is not iterable, assume it does not have children by
# default.
function children(x)
    if applicable(start, x) && !isa(x, Integer) && !isa(x, Char)
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

# Don't consider strings tree-iterable in general
children(x::AbstractString) = ()

# To support iteration over associatives, define printnode on Tuples to return
# the first element. If this doesn't work well in practice it may be better to
# create a special iterator that `children` on `Associative` returns.
# Even better, iteration over associatives should return pairs.

printnode{K,V}(io::IO, kv::Tuple{K,V}) = printnode(io,kv[1])
children{K,V}(kv::Tuple{K,V}) = kv[2]

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
Dict{ASCIIString,Any}("b"=>['c','d'],"a"=>"b")
├─ b
│  ├─ c
│  └─ d
└─ a
   └─ b

julia> print_tree(STDOUT,Dict("a"=>"b","b"=>['c','d']);
        charset = TreeCharSet('+','\\','|',"--"))
Dict{ASCIIString,Any}("b"=>['c','d'],"a"=>"b")
+-- b
|   +-- c
|   \-- d
\-- a
   \-- b
```

"""
function _print_tree(printnode::Function, io::IO, tree, maxdepth = 5; depth = 0, active_levels = Int[],
    charset = TreeCharSet(), withinds = false, inds = [])
    if withinds
        printnode(io, tree, inds)
    else
        printnode(io, tree)
    end
    println(io)
    c = children(tree)
    if c !== ()
        i = start(c)
        while !done(c,i)
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
show(io::IO, tree::Tree) = print_tree(io, tree.x)

type AnnotationNode{T}
    val::T
    children::Array{AnnotationNode{T}}
end

children(x::AnnotationNode) = x.children
printnode(io::IO, x::AnnotationNode) = print(io, x.val)

immutable ShadowTree
    tree::Tree
    shadow::Tree
end

make_zip(x::ShadowTree) = zip(children(x.tree.x),children(x.shadow.x))

function children(x::ShadowTree)
    map(x->ShadowTree(Tree(x[1]), Tree(x[2])),make_zip(x))
end

start(x::ShadowTree) = start(make_zip(x))
next(x::ShadowTree, it) = next(make_zip(x), it)
done(x::ShadowTree, it) = done(make_zip(x), it)

function make_annotations(cb, tree)
    AnnotationNode{Any}(cb(tree), AnnotationNode{Any}[make_annotations(cb, child) for child in children(tree)])
end

function getindex(tree::Tree, indices)
    node = tree.x
    for idx in indices
        node = children(node)[idx]
    end
    node
end

function setindex!(tree::Tree, val, indices)
    setindex!(children(getindex(tree,indices[1:end-1])),val,indices[end])
end


function setindex!(tree::ShadowTree, val, indices)
    setindex!(tree.tree, val[1], indices)
    setindex!(tree.shadow, val[2], indices)
end

# Utitlity Iterator - Should probably be moved elsewhere
immutable IndEnumerate{I}
    itr::I
end
indenumerate(itr) = IndEnumerate(itr)

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

"""
Iterator to visit the nodes of a tree, guaranteeing that children
will be visited before there parents.

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
end

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

function done(leaves::Leaves, idxs)
    idxs[1] > length(children(leaves.tree))
end

done(ti::PostOrderDFS, idxs::Void) = true
done(ti::PostOrderDFS, idxs::Array) = false

function start(ti::TreeIterator, ind=1; c = children(ti.tree))
    if ind <= length(c)
        return [ind, depthfirstinds(c[ind])...]
    else
        return [ind]
    end
end

function next(ti::TreeIterator, idxs)
    (Tree(ti.tree)[idxs], nextind(ti, idxs))
end

end # module
