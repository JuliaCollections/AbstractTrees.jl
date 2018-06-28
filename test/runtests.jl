try
    AbstractTrees
    workspace()
catch
end
using AbstractTrees
using Test
import Base: ==

AbstractTrees.children(x::Array) = x
tree = Any[1,Any[2,3]]

AbstractTrees.print_tree(stdout, tree)
@test collect(Leaves(tree)) == [1,2,3]
@test collect(PostOrderDFS(tree)) == Any[1,2,3,Any[2,3],Any[1,Any[2,3]]]
@test collect(StatelessBFS(tree)) == Any[Any[1,Any[2,3]],1,Any[2,3],2,3]

tree2 = Any[Any[1,2],Any[3,4]]
@test collect(PreOrderDFS(tree2)) == Any[tree2,Any[1,2],1,2,Any[3,4],3,4]

"""
    A tree in which every node has 0 or 1 children
"""
struct OneTree
    nodes::Vector{Int}
end
AbstractTrees.treekind(::Type{OneTree}) = AbstractTrees.IndexedTree()
AbstractTrees.siblinglinks(::Type{OneTree}) = AbstractTrees.StoredSiblings()
AbstractTrees.relative_state(t::OneTree, _, __::Int) = 1
Base.getindex(t::OneTree, idx) = t.nodes[idx]
AbstractTrees.childindices(tree::OneTree, node::Int) =
    (ret = (node == 0 || tree[node] == 0) ? () : (tree[node],))
AbstractTrees.children(tree::OneTree) = AbstractTrees.children(tree, tree)
AbstractTrees.rootstate(tree::OneTree) = 1
AbstractTrees.printnode(io::IO, t::OneTree) =
    AbstractTrees.printnode(io::IO, t[AbstractTrees.rootstate(t)])

ot = OneTree([2,3,4,0])
AbstractTrees.print_tree(stdout, ot)
@test collect(AbstractTrees.Leaves(ot)) == [0]
@test collect(AbstractTrees.PreOrderDFS(ot)) == [2,3,4,0]
@test collect(AbstractTrees.PostOrderDFS(ot)) == [0,4,3,2]

"""
    Stores an explicit parent for some other kind of tree
"""
struct ParentTree{T}
    tree::T
    parents::Vector{Int}
end
AbstractTrees.treekind(::Type{ParentTree{T}}) where {T} = AbstractTrees.treekind(T)
AbstractTrees.parentlinks(::Type{ParentTree{T}}) where {T} = AbstractTrees.StoredParents()
AbstractTrees.siblinglinks(::Type{ParentTree{T}}) where {T} = AbstractTrees.siblinglinks(T)
AbstractTrees.relative_state(t::ParentTree, x, r::Int) =
    AbstractTrees.relative_state(t.tree, x, r)
Base.getindex(t::ParentTree, idx) = t.tree[idx]
AbstractTrees.childindices(tree::ParentTree, node::Int) = AbstractTrees.childindices(tree.tree, node)
AbstractTrees.children(tree::ParentTree) = AbstractTrees.children(tree, tree)
AbstractTrees.rootstate(tree::ParentTree) = AbstractTrees.rootstate(tree.tree)
AbstractTrees.parentind(tree::ParentTree, node::Int) = tree.parents[node]
AbstractTrees.printnode(io::IO, t::ParentTree) =
    AbstractTrees.printnode(io::IO, t[AbstractTrees.rootstate(t)])

pt = ParentTree(ot,[0,1,2,3])
AbstractTrees.print_tree(stdout, pt)
@test collect(AbstractTrees.Leaves(pt)) == [0]
@test collect(AbstractTrees.PreOrderDFS(pt)) == [2,3,4,0]
@test collect(AbstractTrees.PostOrderDFS(pt)) == [0,4,3,2]

# Test modification while iterating over PreOrderDFS
a = [1,[2,[3]]]
b = treemap!(PreOrderDFS(a)) do node
    !isa(node, Vector) && return node
    ret = pushfirst!(copy(node),0)
    # And just for good measure stomp over the old node to make sure nothing
    # is cached.
    empty!(node)
    ret
end
@assert b == Any[0,1,Any[0,2,[0,3]]]

#=
immutable IntTree
    num::Int
    children::Vector{IntTree}
end
==(x::IntTree,y::IntTree) = x.num == y.num && x.children == y.children

@test treemap(PostOrderDFS(tree)) do ind, x, children
    IntTree(isa(x,Int) ? x : mapreduce(x->x.num,+,0,children),
        isempty(children) ? IntTree[] : children)
end == IntTree(6,[IntTree(1,IntTree[]),IntTree(5,[IntTree(2,IntTree[]),IntTree(3,IntTree[])])])

@test collect(PostOrderDFS([])) == Any[[]]
=#
