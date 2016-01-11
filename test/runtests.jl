using AbstractTrees
using Base.Test

AbstractTrees.children(x::Array) = x
tree = Any[1,Any[2,3]]

AbstractTrees.print_tree(STDOUT, tree)
@test collect(Leaves(tree)) == [1,2,3]
@test collect(PostOrderDFS(tree)) == Any[1,2,3,Any[2,3],Any[1,Any[2,3]]]
