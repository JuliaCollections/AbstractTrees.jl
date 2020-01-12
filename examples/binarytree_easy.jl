# This file demonstrates a relatively simple way to implement the AbstractTrees
# interface for a classic binary tree. See "binarytree_infer.jl" for a more performant
# (but laborious) approach.

if !isdefined(@__MODULE__, :BinaryNode)
    include("binarytree_core.jl")
end

## Things we need to define
function AbstractTrees.children(node::BinaryNode)
    if isdefined(node, :left)
        if isdefined(node, :right)
            return (node.left, node.right)
        end
        return (node.left,)
    end
    isdefined(node, :right) && return (node.right,)
    return ()
end

## Things that make printing prettier
AbstractTrees.printnode(io::IO, node::BinaryNode) = print(io, node.data)

## Optional enhancements
# These next two definitions allow inference of the item type in iteration.
# (They are not sufficient to solve all internal inference issues, however.)
Base.eltype(::Type{<:TreeIterator{BinaryNode{T}}}) where T = BinaryNode{T}
Base.IteratorEltype(::Type{<:TreeIterator{BinaryNode{T}}}) where T = Base.HasEltype()

## Let's test it. First build a tree.
root = BinaryNode(0)
l = leftchild(1, root)
r = rightchild(2, root)
lr = rightchild(3, l)

print_tree(root)
collect(PostOrderDFS(root))
@static if isdefined(@__MODULE__, :Test)
    @testset "binarytree_easy.jl" begin
        @test [node.data for node in PostOrderDFS(root)] == [3, 1, 2, 0]
        @test [node.data for node in PreOrderDFS(root)] == [0, 1, 3, 2]
        @test [node.data for node in Leaves(root)] == [3, 2]
    end
end
