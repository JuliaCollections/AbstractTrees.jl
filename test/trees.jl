using AbstractTrees
using Test

include(joinpath(@__DIR__,"examples","idtree.jl"))

@testset "IDTree" begin
    tree = IDTree(1 => [
        2 => [
            3,
            4 => [5],
        ],
        6,
        7 => [
            8 => [
                9,
                10,
                11 => 12:14,
                15,
            ],
        ],
        16,
    ])

    nodes = [tree.nodes[id] for id in 1:16]

    # Node/subtree properties
    #                              1   2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
    @test treesize.(nodes)    == [16, 4, 1, 2, 1, 1, 9, 8, 1, 1, 4, 1, 1, 1, 1, 1]
    @test treebreadth.(nodes) == [10, 2, 1, 1, 1, 1, 6, 6, 1, 1, 3, 1, 1, 1, 1, 1]
    @test treeheight.(nodes)  == [ 4, 2, 0, 1, 0, 0, 3, 2, 0, 0, 1, 0, 0, 0, 0, 0]

    # Child/descendant checking
    @test ischild(nodes[2], nodes[1])
    @test ischild(nodes[3], nodes[2])
    @test !ischild(nodes[3], nodes[1])
    @test !ischild(nodes[1], nodes[2])
    @test !ischild("foo", nodes[1])
    @test !ischild(nodes[1], "foo")

    @test isdescendant(nodes[2], nodes[1])
    @test isdescendant(nodes[9], nodes[1])
    @test isdescendant(nodes[12], nodes[7])
    @test !isdescendant(nodes[1], nodes[2])
    @test !isdescendant(nodes[4], nodes[8])
    @test !isdescendant(nodes[1], nodes[1])
    @test !isdescendant("foo", nodes[1])
    @test !isdescendant(nodes[1], "foo")

    @test intree(nodes[2], nodes[1])
    @test intree(nodes[9], nodes[1])
    @test intree(nodes[12], nodes[7])
    @test !intree(nodes[1], nodes[2])
    @test !intree(nodes[4], nodes[8])
    @test intree(nodes[1], nodes[1])
    @test !intree("foo", nodes[1])
    @test !intree(nodes[1], "foo")

    # Traversal
    @test [n.id for n in PreOrderDFS(tree.root)] == 1:16
    @test [n.id for n in PostOrderDFS(tree.root)] == [3, 5, 4, 2, 6, 9, 10, 12, 13, 14, 11, 15, 8, 7, 16, 1]
    @test [n.id for n in Leaves(tree.root)] == [3, 5, 6, 9, 10, 12, 13, 14, 15, 16]
end

include(joinpath(@__DIR__,"examples","onenode.jl"))

@testset "OneNode" begin
    ot = OneNode([2,3,4,0], 1)
    @inferred collect(Leaves(ot))
    @test nodevalue.(collect(Leaves(ot))) == [0]
    @test eltype(nodevalue.(collect(Leaves(ot)))) ≡ Int
    @test nodevalue.(collect(PreOrderDFS(ot))) == [2,3,4,0]
    @test nodevalue.(collect(PostOrderDFS(ot))) == [0,4,3,2]
end

include(joinpath(@__DIR__,"examples","onetree.jl"))

@testset "OneTree" begin
    ot = OneTree([2,3,4,0])
    n = IndexNode(ot)

    @inferred collect(Leaves(n))
    @test nodevalue.(collect(Leaves(n))) == [0]
    @test eltype(nodevalue.(collect(Leaves(n)))) ≡ Int
    @test nodevalue.(collect(PreOrderDFS(n))) == [2,3,4,0]
    @test nodevalue.(collect(PostOrderDFS(n))) == [0,4,3,2]
end

@testset "treemap" begin
    a = [1,[2,[3]]]
    f = n -> n isa AbstractArray ? (nothing, children(n)) : (n+1, children(n))
    b = treemap(f, a)
    @test nodevalue.(PreOrderDFS(b)) == [nothing, 2, nothing, 3, nothing, 4]
    g = n -> isempty(children(n)) ? (nodevalue(n), ()) : (nothing, [0; children(n)])
    b = treemap(g, a)
    @test nodevalue.(PostOrderDFS(b)) == [0, 1, 0, 2, 0, 3, nothing, nothing, nothing]
end

#=
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
    (v"1.6-" < VERSION < v"1.7-") || @inferred first(iter) # 1.6 has a weird inference bug
    @test first(iter) == IntTree(2, IntTree[])
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
=#
