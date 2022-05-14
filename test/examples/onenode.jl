using AbstractTrees

"""
    OneNode

The node of a tree in which every node has 0 or 1 children.
"""
struct OneNode
    nodes::Vector{Int}
    idx::Int
end

AbstractTrees.ChildIndexing(::Type{OneNode}) = IndexedChildren()
AbstractTrees.ParentLinks(::Type{OneNode}) = StoredParents()
AbstractTrees.SiblingLinks(::Type{OneNode}) = StoredSiblings()

AbstractTrees.parent(ot::OneNode) = ot.idx == 1 ? nothing : OneNode(ot.nodes, ot.idx-1)

# no nodes ever have siblings
AbstractTrees.nextsibling(ot::OneNode) = nothing

AbstractTrees.nodevalue(ot::OneNode) = ot.nodes[ot.idx]

# this guarantees that all nodes in the tree have the same type
Base.IteratorEltype(::Type{<:TreeIterator{OneNode}}) = Base.HasEltype()
Base.eltype(::Type{<:TreeIterator{OneNode}}) = OneNode

function AbstractTrees.children(ot::OneNode)
    idx = ot.idx + 1
    idx > length(ot.nodes) ? () : (OneNode(ot.nodes, idx),)
end
