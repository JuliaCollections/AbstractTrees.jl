# This file illustrates how to create inferrable tree-iteration methods in circumstances
# where the children are not naturally indexable.
# See "binarytree_easy.jl" for a simpler approach.

if !isdefined(@__MODULE__, :BinaryNode)
    include("binarytree_core.jl")
end

## Enhancement of the "native" binary tree
# You might have the methods below even if you weren't trying to support AbstractTrees.

# Implement iteration over the immediate children of a node
function Base.iterate(node::BinaryNode)
    isdefined(node, :left) && return (node.left, false)
    isdefined(node, :right) && return (node.right, true)
    return nothing
end
function Base.iterate(node::BinaryNode, state::Bool)
    state && return nothing
    isdefined(node, :right) && return (node.right, true)
    return nothing
end
Base.IteratorSize(::Type{BinaryNode{T}}) where T = Base.SizeUnknown()
Base.eltype(::Type{BinaryNode{T}}) where T = BinaryNode{T}

## Things we need to define to leverage the native iterator over children
## for the purposes of AbstractTrees.
# Set the traits of this kind of tree
Base.eltype(::Type{<:TreeIterator{BinaryNode{T}}}) where T = BinaryNode{T}
Base.IteratorEltype(::Type{<:TreeIterator{BinaryNode{T}}}) where T = Base.HasEltype()
AbstractTrees.parentlinks(::Type{BinaryNode{T}}) where T = AbstractTrees.StoredParents()
AbstractTrees.siblinglinks(::Type{BinaryNode{T}}) where T = AbstractTrees.StoredSiblings()
# Use the native iteration for the children
AbstractTrees.children(node::BinaryNode) = node

Base.parent(root::BinaryNode, node::BinaryNode) = isdefined(node, :parent) ? node.parent : nothing

function AbstractTrees.nextsibling(tree::BinaryNode, child::BinaryNode)
    isdefined(child, :parent) || return nothing
    p = child.parent
    if isdefined(p, :right)
        child === p.right && return nothing
        return p.right
    end
    return nothing
end

# We also need `pairs` to return something sensible.
# If you don't like integer keys, you could do, e.g.,
#   Base.pairs(node::BinaryNode) = BinaryNodePairs(node)
# and have its iteration return, e.g., `:left=>node.left` and `:right=>node.right` when defined.
# But the following is easy:
Base.pairs(node::BinaryNode) = enumerate(node)


AbstractTrees.printnode(io::IO, node::BinaryNode) = print(io, node.data)

root = BinaryNode(0)
l = leftchild(1, root)
r = rightchild(2, root)
lr = rightchild(3, l)

print_tree(root)
collect(PostOrderDFS(root))
@static if isdefined(@__MODULE__, :Test)
    @testset "binarytree_infer.jl" begin
        @test @inferred(map(x->x.data, PostOrderDFS(root))) == [3, 1, 2, 0]
        @test @inferred(map(x->x.data, PreOrderDFS(root))) == [0, 1, 3, 2]
        @test @inferred(map(x->x.data, Leaves(root))) == [3, 2]
    end
end
