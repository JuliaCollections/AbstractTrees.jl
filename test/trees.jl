using AbstractTrees
using Test

include(joinpath(@__DIR__, "examples", "idtree.jl"))

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
    @test treesize.(nodes) == [16, 4, 1, 2, 1, 1, 9, 8, 1, 1, 4, 1, 1, 1, 1, 1]
    @test treebreadth.(nodes) == [10, 2, 1, 1, 1, 1, 6, 6, 1, 1, 3, 1, 1, 1, 1, 1]
    @test treeheight.(nodes) == [4, 2, 0, 1, 0, 0, 3, 2, 0, 0, 1, 0, 0, 0, 0, 0]

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

include(joinpath(@__DIR__, "examples", "onenode.jl"))

@testset "OneNode" begin
    ot = OneNode([2, 3, 4, 0], 1)
    @inferred collect(Leaves(ot))
    @test nodevalue.(collect(Leaves(ot))) == [0]
    @test eltype(nodevalue.(collect(Leaves(ot)))) ≡ Int
    @test nodevalue.(collect(PreOrderDFS(ot))) == [2, 3, 4, 0]
    @test nodevalue.(collect(PostOrderDFS(ot))) == [0, 4, 3, 2]
end

include(joinpath(@__DIR__, "examples", "onetree.jl"))

@testset "OneTree" begin
    ot = OneTree([2, 3, 4, 0])
    n = IndexNode(ot)

    @inferred collect(Leaves(n))
    @test nodevalue.(collect(Leaves(n))) == [0]
    @test eltype(nodevalue.(collect(Leaves(n)))) ≡ Int
    @test nodevalue.(collect(PreOrderDFS(n))) == [2, 3, 4, 0]
    @test nodevalue.(collect(PostOrderDFS(n))) == [0, 4, 3, 2]
end

include(joinpath(@__DIR__, "examples", "fstree.jl"))

@testset "FSNode" begin
    Base.VERSION >= v"1.6" && mk_tree_test_dir() do path
        tree = Directory(".")

        ls = nodevalue.(collect(Leaves(tree)))
        # use set so we don't have to guarantee ordering
        @test Set(ls) == Set([joinpath(".", "A", "f2"), joinpath(".", "B"), joinpath(".", "f1")])
        @test treeheight(tree) == 2
    end
end

include(joinpath(@__DIR__, "examples", "binarytree.jl"))

@testset "BinaryNode" begin
    t = binarynode_example()

    ls = @inferred collect(Leaves(t))
    @test nodevalue.(ls) == [3, 2]

    predfs = @inferred collect(PreOrderDFS(t))
    @test nodevalue.(predfs) == [0, 1, 3, 2]

    postdfs = @inferred collect(PostOrderDFS(t))
    @test nodevalue.(postdfs) == [3, 1, 2, 0]

    sbfs = @inferred collect(StatelessBFS(t))
    @test nodevalue.(sbfs) == [0, 1, 2, 3]
end

