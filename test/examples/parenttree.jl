
#TODO: haven't decided how to do this yet

struct ParentNode{T}
    node::T
    parents::Vector{T}
end

AbstractTrees.ParentLinks(::Type{<:ParentNode}) = StoredParents()

AbstractTrees.SiblingLinks(::Type{<:ParentNode}) = StoredSiblings()

AbstractTrees.nodevalue(pn::ParentNode) = nodevalue(pn.node)

function AbstractTrees.parent(pn::ParentNode)
    
end
