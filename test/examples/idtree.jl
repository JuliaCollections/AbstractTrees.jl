using AbstractTrees

struct IDTreeNode
    id::Int
    children::Vector{IDTreeNode}

    IDTreeNode(id::Integer, children::Vector{IDTreeNode}=IDTreeNode[]) = new(id, children)
end

AbstractTrees.children(node::IDTreeNode) = node.children
AbstractTrees.printnode(io::IO, node::IDTreeNode) = print(io, "#", node.id)

"""
    IDTree

Basic tree type used for testing.

Each node has a unique ID, making them easy to reference. Node children are ordered.

Node type only implements `children`, so serves to test default implementations of most functions.
"""
struct IDTree
    nodes::Dict{Int,IDTreeNode}
    root::IDTreeNode
end

_make_idtreenode(id::Integer) = IDTreeNode(id)
_make_idtreenode((id, children)::Pair{<:Integer, <:Any}) = IDTreeNode(id, _make_idtreenode.(children))

"""
    IDTree(x)

Create from nested `id => children` pairs. Leaf nodes may be represented by ID only.
"""
function IDTree(x)
    root = _make_idtreenode(x)
    nodes = Dict{Int, IDTreeNode}()

    for node in PreOrderDFS(root)
        haskey(nodes, node.id) && error("Duplicate node ID $(node.id)")
        nodes[node.id] = node
    end

    return IDTree(nodes, root)
end


