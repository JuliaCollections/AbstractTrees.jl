
struct RefNode{N,T}
    node::N
    tree::T
end

ParentLinks(::Type{<:RefNode{N,T}}) where {N,T} = ParentLinks(T)
SiblingLinks(::Type{<:RefNode{N,T}}) where {N,T} = SiblingLinks(T)

nodevalue(rn::RefNode) = rn.tree[rn.node]

children(rn::RefNode) = Iterators.map(c -> RefNode(rn.node, rn.tree), children(rn.tree, rn.node))

parent(rn::RefNode) = parent(rn.tree, rn.node)

nextsibling(rn::RefNode) = nextsibling(rn.tree, rn.node)

prevsibling(rn::RefNode) = prevsibling(rn.tree, rn.node)
