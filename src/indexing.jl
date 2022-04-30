
"""
    childindex(node, idx)

Obtain a node from a tree with [`IndexedChildren()`] by indexing each level of the tree with the elements
of `idx`.

## Example
```julia
v = [1, [2, [3, 4]]]

childindex(v, (2, 2, 1)) == 3
```
"""
function childindex(::IndexedChildren, node, idx)
    n = node
    for j ∈ idx
        n = children(n)[j]
    end
    n
end
childindex(node, idx) = childindex(ChildIndexing(node), t, idx)

"""
    Indexed{T,C}

A wrapper of a tree node of type `T` with children of type `C` which guarantees that children can be indexed.
Construction involves allocation of an array of the children.

Typically one should use [`indexed`](@ref) to construct this.
"""
struct Indexed{T,C}
    node::T
    children::Vector{C}
end

"""
    indexed(node)

Return a tree node which is guaranteed to have [`IndexedChildren`](@ref).  If `node` already has this, `indexed` is
the identity, otherwise it will wrap the node in an [`Indexed`](@ref).
"""
indexed(::IndexedChildren, node) = node
indexed(::NonIndexedChildren, node) = Indexed(node)
indexed(node) = indexed(ChildIndexing(node), node)

function Indexed(node)
    ch = map(indexed, children(node))
    isempty(ch) && return Indexed{typeof(node),Union{}}(node, [])
    Indexed{typeof(node),eltype(ch)}(node, ch)
end

unwrap(inode::Indexed) = inode.node

ChildIndexing(::Indexed) = IndexedChildren()

childrentype(::Type{Indexed{T,C}}) where {T,C} = Vector{C}

children(inode::Indexed) = inode.children
