using AbstractTrees

"""
    OneTree

A tree in which each node has 0 or 1 children.
"""
struct OneTree
    nodes::Vector{Int}
end

AbstractTrees.ParentLinks(::Type{OneTree}) = StoredParents()
AbstractTrees.SiblingLinks(::Type{OneTree}) = StoredSiblings()

AbstractTrees.rootindex(::OneTree) = 1

function AbstractTrees.childindices(ot::OneTree, idx::Integer)
    idx == length(ot.nodes) ? () : (idx+1,)
end

AbstractTrees.nodevalue(ot::OneTree, idx::Integer) = ot.nodes[idx]

AbstractTrees.parentindex(ot::OneTree, idx::Integer) = (idx == 1) ? nothing : idx-1

AbstractTrees.nextsiblingindex(::OneTree, ::Integer) = nothing

AbstractTrees.prevsiblingindex(::OneTree, ::Integer) = nothing

Base.IteratorEltype(::Type{<:TreeIterator{<:IndexNode{OneTree}}}) = Base.HasEltype()
Base.eltype(::Type{<:TreeIterator{<:IndexNode{OneTree}}}) = IndexNode{OneTree,Int}
