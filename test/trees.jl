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
Base.eltype(::Type{<:TreeIterator{OneTree}}) = Int
Base.IteratorEltype(::Type{<:TreeIterator{OneTree}}) = Base.HasEltype()

@testset "OneTree" begin
    ot = OneTree([2,3,4,0])
    @test repr_tree(ot) == "2\n└─ 3\n   └─ 4\n      └─ 0\n"
    @test @inferred(collect(Leaves(ot))) == [0]
    @test eltype(collect(Leaves(ot))) === Int
    @test collect(PreOrderDFS(ot)) == [2,3,4,0]
    @test collect(PostOrderDFS(ot)) == [0,4,3,2]
end


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

@testset "ParentTree" begin
    ot = OneTree([2,3,4,0])
    pt = ParentTree(ot,[0,1,2,3])

    @test repr_tree(pt) == "2\n└─ 3\n   └─ 4\n      └─ 0\n"
    @test collect(Leaves(pt)) == [0]
    @test collect(PreOrderDFS(pt)) == [2,3,4,0]
    @test collect(PostOrderDFS(pt)) == [0,4,3,2]

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
    @test b == Any[0,1,Any[0,2,[0,3]]]
end


struct IntTree
    num::Int
    children::Vector{IntTree}
end
==(x::IntTree,y::IntTree) = x.num == y.num && x.children == y.children
AbstractTrees.children(itree::IntTree) = itree.children
Base.eltype(::Type{<:TreeIterator{IntTree}}) = IntTree
Base.IteratorEltype(::Type{<:TreeIterator{IntTree}}) = Base.HasEltype()
AbstractTrees.nodetype(::IntTree) = IntTree

@testset "IntTree" begin
    itree = IntTree(1, [IntTree(2, IntTree[])])
    iter = Leaves(itree)
    @test @inferred(first(iter)) == IntTree(2, IntTree[])
    val, state = iterate(iter)
    @test Base.return_types(iterate, Tuple{typeof(iter), typeof(state)}) ==
        [Union{Nothing, Tuple{IntTree,typeof(state)}}]
end


#=
@test treemap(PostOrderDFS(tree)) do ind, x, children
    IntTree(isa(x,Int) ? x : mapreduce(x->x.num,+,0,children),
        isempty(children) ? IntTree[] : children)
end == IntTree(6,[IntTree(1,IntTree[]),IntTree(5,[IntTree(2,IntTree[]),IntTree(3,IntTree[])])])
=#

@test collect(PostOrderDFS([])) == Any[[]]
