using AbstractTrees
using Test

@testset "Array" begin
    tree = Any[1,Any[2,3]]

    @test collect(Leaves(tree)) == [1,2,3]
    @test collect(Leaves(tree)) isa Vector{Int}
    @test collect(PostOrderDFS(tree)) == Any[1,2,3,Any[2,3],Any[1,Any[2,3]]]
    @test collect(StatelessBFS(tree)) == Any[Any[1,Any[2,3]],1,Any[2,3],2,3]

    @test treesize(tree) == 5
    @test treebreadth(tree) == 3
    @test treeheight(tree) == 2

    @test ischild(1, tree)
    @test !ischild(2, tree)
    @test ischild(tree[2], tree)
    @test !ischild(copy(tree[2]), tree)  # Should work on identity, not equality

    @test isdescendant(1, tree)
    @test isdescendant(2, tree)
    @test !isdescendant(4, tree)
    @test isdescendant(tree[2], tree)
    @test !isdescendant(copy(tree[2]), tree)
    @test !isdescendant(tree, tree)

    @test intree(1, tree)
    @test intree(2, tree)
    @test !intree(4, tree)
    @test intree(tree[2], tree)
    @test !intree(copy(tree[2]), tree)
    @test intree(tree, tree)


    tree2 = Any[Any[1,2],Any[3,'4']]
    @test collect(PreOrderDFS(tree2)) == Any[tree2,Any[1,2],1,2,Any[3,'4'],3,'4']

    @test treesize(tree2) == 7
    @test treebreadth(tree2) == 4
    @test treeheight(tree2) == 2


    tree3 = []
    for itr in [Leaves, PreOrderDFS, PostOrderDFS]
        @test collect(itr(tree3)) == [tree3]
    end

    @test treesize(tree3) == 1
    @test treebreadth(tree3) == 1
    @test treeheight(tree3) == 0
end


@testset "Pair" begin
    tree = 1=>(3=>4)
    @test collect(PreOrderDFS(tree)) == Any[tree, tree.second, 4]
end

@testset "Expr" begin
    expr = :(foo(x^2 + 3))

    @test children(expr) == expr.args

    @test collect(Leaves(expr)) == [:foo, :+, :^, :x, 2, 3]
end

