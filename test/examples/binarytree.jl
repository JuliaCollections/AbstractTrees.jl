using AbstractTrees


mutable struct BinaryNode{T}
    data::T
    parent::Union{Nothing,BinaryNode{T}}
    left::Union{Nothing,BinaryNode{T}}
    right::Union{Nothing,BinaryNode{T}}

    function BinaryNode{T}(data, parent=nothing, l=nothing, r=nothing) where T
        new{T}(data, parent, l, r)
    end
end
BinaryNode(data) = BinaryNode{typeof(data)}(data)

function leftchild!(parent::BinaryNode, data)
    isnothing(parent.left) || error("left child is already assigned")
    node = typeof(parent)(data, parent)
    parent.left = node
end
function rightchild!(parent::BinaryNode, data)
    isnothing(parent.right) || error("right child is already assigned")
    node = typeof(parent)(data, parent)
    parent.right = node
end

## Things we need to define
function AbstractTrees.children(node::BinaryNode)
    if isnothing(node.left) && isnothing(node.right)
        ()
    elseif isnothing(node.left) && !isnothing(node.right)
        (node.right,)
    elseif !isnothing(node.left) && isnothing(node.right)
        (node.left,)
    else
        (node.left, node.right)
    end
end

AbstractTrees.nodevalue(n::BinaryNode) = n.data

AbstractTrees.ParentLinks(::Type{<:BinaryNode}) = StoredParents()

AbstractTrees.parent(n::BinaryNode) = n.parent

## Optional enhancements
# These next two definitions allow inference of the item type in iteration.
# (They are not sufficient to solve all internal inference issues, however.)
Base.eltype(::Type{<:TreeIterator{BinaryNode{T}}}) where T = BinaryNode{T}
Base.IteratorEltype(::Type{<:TreeIterator{BinaryNode{T}}}) where T = Base.HasEltype()

function binarynode_example()
    n₀ = BinaryNode(0)
    l₁ = leftchild!(n₀, 1)
    r₁ = rightchild!(n₀, 2)
    r₂ = rightchild!(l₁, 3)

    n₀
end
