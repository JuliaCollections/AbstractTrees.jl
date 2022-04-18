
function childindex(::IndexedChildren, t, idx)
    n = t
    for j ∈ idx
        n = children(n)[j]
    end
    n
end
childindex(t, idx) = childindex(childindexing(t), t, idx)


# obviously this is inefficient so it should only be used if indexing not otherwise available
# expects children to also be indexed
struct Indexed{T,C}
    node::T
    children::Vector{C}
end

indexed(::IndexedChildren, t) = t
indexed(::NonIndexedChildren, t) = Indexed(t)
indexed(t) = indexed(childindexing(t), t)

function Indexed(node)
    ch = map(indexed, children(node))
    isempty(ch) && return Indexed{typeof(node),Union{}}(node, [])
    Indexed{typeof(node),eltype(ch)}(node, ch)
end

unwrap(inode::Indexed) = inode.node

childindexing(::Indexed) = IndexedChildren()

children(inode::Indexed) = inode.children

# this automatically unwraps... not sure how good an idea that is but why not
Base.getindex(t::Indexed, idx) = unwrap(childindex(t, idx))
