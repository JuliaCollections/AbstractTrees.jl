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

    @test collect(PostOrderDFS([])) == Any[[]]
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

@testset "Array-Dict" begin
    t = [1, 2, Dict("a"=>3, "b"=>[4,5])]
    @test Set(Leaves(t)) == Set(1:5)  # don't want to guarantee ordering because of dict

    t = [1, Dict("a"=>2)]
    @test collect(Leaves(t)) == [1, 2]
    @test collect(PreOrderDFS(t)) == [t, 1, t[2], "a"=>2, 2]
    @test collect(PostOrderDFS(t)) == [1, 2, "a"=>2, t[2], t]
end

@testset "treemap" begin
    a = [1,[2,[3]]]
    f = n -> n isa AbstractArray ? (nothing, children(n)) : (n+1, children(n))
    b = treemap(f, a)
    @test collect(nodevalues(PreOrderDFS(b))) == [nothing, 2, nothing, 3, nothing, 4]
    g = n -> isempty(children(n)) ? (nodevalue(n), ()) : (nothing, [0; children(n)])
    b = treemap(g, a)
    @test nodevalue.(PostOrderDFS(b)) == [0, 1, 0, 2, 0, 3, nothing, nothing, nothing]
end

@testset "StableNode" begin
    t = [1,[2,3,[4,5]]]

    n = StableNode{Union{Int,Nothing}}(t) do m
        m isa Integer ? convert(Int, m) : nothing
    end

    @test treeheight(n) == 3
    @test treebreadth(n) == 5

    @test typeof(TreeCursor(n)) == AbstractTrees.StableIndexedCursor{StableNode{Union{Int,Nothing}}}

    ls = @inferred collect(Leaves(n))
    ls = nodevalue.(ls)
    @test eltype(ls) <: Union{Nothing,Int}
    @test nodevalue.(ls) == 1:5

    ns = @inferred collect(PreOrderDFS(n))
    ns = nodevalue.(ns)
    @test eltype(ns) == Union{Nothing,Int}
    @test ns == [nothing, 1, nothing, 2, 3, nothing, 4, 5]
end
