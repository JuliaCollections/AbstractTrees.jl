using AbstractTrees
using Base.Test
import Base: ==

AbstractTrees.children(x::Array) = x
tree = Any[1,Any[2,3]]

AbstractTrees.print_tree(STDOUT, tree)
@test collect(Leaves(tree)) == [1,2,3]
@test collect(PostOrderDFS(tree)) == Any[1,2,3,Any[2,3],Any[1,Any[2,3]]]
@test collect(StatelessBFS(tree)) == Any[Any[1,Any[2,3]],1,Any[2,3],2,3]

tree2 = Any[Any[1,2],Any[3,4]]
@test collect(PreOrderDFS(tree2)) == Any[tree2,Any[1,2],1,2,Any[3,4],3,4]

immutable IntTree
    num::Int
    children::Vector{IntTree}
end
==(x::IntTree,y::IntTree) = x.num == y.num && x.children == y.children

@test treemap(PostOrderDFS(tree)) do x, children
    IntTree(isa(x,Int) ? x : mapreduce(x->x.num,+,0,children),
        isempty(children) ? IntTree[] : children)
end == IntTree(6,[IntTree(1,IntTree[]),IntTree(5,[IntTree(2,IntTree[]),IntTree(3,IntTree[])])])
