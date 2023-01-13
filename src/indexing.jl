
"""
    getdescendant(node, idx)

Obtain a node from a tree by indexing each level of the tree with the elements of `idx`.

This function is defined for all trees regardless of whether they have the [`IndexedChildren`](@ref).
This is because a tree without [`IndexedChildren`](@ref) might have special cases in which all children
are indexable, a prominent example being `Array` which may not have indexable sub-trees (e.g. an
array containing a Dict) but there are common special cases in which array trees are fully indexable
(e.g. a tree in which every non-leaf node is an array).

The elements of `idx` can be any argument to `getindex`, not necessarily integers.  For example,
`getdescendant(Dict("a"=>1), ("a",))` returns `1`.

Note that this is a separate concept from indexed trees which by default do not have `IndexedChildren()`,
see [`IndexNode`](@ref).

## Example
```julia
v = [1, [2, [3, 4]]]

getdescendant(v, (2, 2, 1)) == 3
```
"""
function getdescendant(node, idx)
    n = node
    for j ∈ idx
        n = children(n)[j]
    end
    n
end


"""
    childindices(tree, node_index)

Get the indices of the children of the node of tree `tree` specified by `node_index`.

To be consistent with [`children`](@ref), by default this returns an empty tuple.

**REQUIRED** for indexed trees:  Indexed trees, i.e. trees that do not implement [`children`](@ref) must implement
this function.
"""
childindices(tree, idx) = ()

"""
    parentindex(tree, node_index)

Get the index of the parent of the node of tree `tree` specified by `node_index`.

Nodes that have no parent (i.e. the root node) should return `nothing`.

**OPTIONAL**: Indexed trees with the [`StoredParents`](@ref) trait must implement this.
"""
function parentindex end

"""
    nextsiblingindex(tree, node_index)

Get the index of the next sibling of the node of tree `tree` specified by `node_index`.

Nodes which have no next sibling should return `nothing`.

**OPTIONAL**: Indexed trees with the [`StoredSiblings`](@ref) trait must implement this.
"""
function nextsiblingindex end

"""
    prevsiblingindex(tree, node_index)

Get the index of the previous sibling of the node of tree `tree` specified by `node_index`.

Nodes which have no previous sibling should return `nothing`.

**OPTIONAL**: Indexed trees that have [`StoredSiblings`](@ref) can implement this, but no built-in tree algorithms
require it.
"""
function prevsiblingindex end

"""
    rootindex(tree)

Get the root index of the indexed tree `tree`.

**OPTIONAL**: The single-argument constructor for [`IndexNode`](@ref) requires this, but it is not required for
any built-in tree algorithms.
"""
function rootindex end

"""
    IndexNode{T,I}

The node of a tree which implements the indexed tree interface.  Such a tree consists of an object `tree` from
which nodes can be obtained with the two-argument method of [`nodevalue`](@ref) which by default calls `getindex`.

An `IndexNode` implements the tree interface, and can be thought of an adapter from an object that implements the
indexed tree interface to one that implements the tree interface.

`IndexNode` do not store the value associated with the node but can obtain it by calling [`nodevalue`](@ref).

## Constructors
```julia
IndexNode(tree, node_index)

IndexNode(tree) = IndexNode(tree, rootindex(tree))  # one-argument constructor requires `rootindex`
```

Here `tree` is an object which stores or can obtain information for the entire tree structure, and `node_index`
is the index of the node for which `node_index` is being constructed.
"""
struct IndexNode{T,I}
    tree::T
    index::I
end

IndexNode(tree) = IndexNode(tree, rootindex(tree))

ParentLinks(::Type{<:IndexNode{N,T}}) where {N,T} = ParentLinks(T)
SiblingLinks(::Type{<:IndexNode{N,T}}) where {N,T} = SiblingLinks(T)

nodevalue(idx::IndexNode) = nodevalue(idx.tree, idx.index)

children(idx::IndexNode) = Iterators.map(c -> IndexNode(idx.tree, c), childindices(idx.tree, idx.index))

function parent(idx::IndexNode)
    pidx = parentindex(idx.tree, idx.index)
    isnothing(pidx) ? nothing : IndexNode(idx.tree, pidx)
end

function nextsibling(idx::IndexNode)
    sidx = nextsiblingindex(idx.tree, idx.index)
    isnothing(sidx) ? nothing : IndexNode(idx.tree, sidx)
end

function prevsibling(idx::IndexNode)
    sidx = prevsiblingindex(idx.tree, idx.index)
    isnothing(sidx) ? nothing : IndexNode(idx.tree, sidx)
end
