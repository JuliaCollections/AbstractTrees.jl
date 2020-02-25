using AbstractTrees
using Test
import Base: ==


if VERSION >= v"1.1.0-DEV.838" # requires https://github.com/JuliaLang/julia/pull/30291
    @testset "Ambiguities" begin
        @test isempty(detect_ambiguities(AbstractTrees, Base, Core))
    end
end


@testset "Array" begin
    tree = Any[1,Any[2,3]]
    io = IOBuffer()
    print_tree(io, tree)
    @test String(take!(io)) == "Array{Any,1}\n├─ 1\n└─ Array{Any,1}\n   ├─ 2\n   └─ 3\n"
    @test collect(Leaves(tree)) == [1,2,3]
    @test collect(Leaves(tree)) isa Vector{Int}
    @test collect(PostOrderDFS(tree)) == Any[1,2,3,Any[2,3],Any[1,Any[2,3]]]
    @test collect(StatelessBFS(tree)) == Any[Any[1,Any[2,3]],1,Any[2,3],2,3]

    tree2 = Any[Any[1,2],Any[3,4]]
    @test collect(PreOrderDFS(tree2)) == Any[tree2,Any[1,2],1,2,Any[3,4],3,4]
end


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
    io = IOBuffer()
    print_tree(io, ot)
    @test String(take!(io)) == "2\n└─ 3\n   └─ 4\n      └─ 0\n"
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
    io = IOBuffer()
    print_tree(io, pt)
    @test String(take!(io)) == "2\n└─ 3\n   └─ 4\n      └─ 0\n"
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

@testset "Examples" begin
    # Ensure the examples run
    exampledir = joinpath(dirname(@__DIR__), "examples")
    examples = readdir(exampledir)
    mktemp() do filename, io
        redirect_stdout(io) do
            for ex in examples
                haskey(ENV, "CI") && Sys.isapple() && ex == "fstree.jl" && continue
                include(joinpath(exampledir, ex))
            end
        end
    end
end


struct Num{I} end
Num(I::Int) = Num{I}()
Base.show(io::IO, ::Num{I}) where {I} = print(io, I)
AbstractTrees.children(x::Num{I}) where {I} = (Num(I+1), Num(I+1))

struct SingleChildInfiniteDepth end
AbstractTrees.children(::SingleChildInfiniteDepth) = (SingleChildInfiniteDepth(),)

@testset "Test print_tree truncation" begin

    # test that `print_tree(headnode, maxdepth)` truncates the output at right depth
    # julia > print_tree(Num(0), 3)
    # 0
    # ├─ 1
    # │  ├─ 2
    # │  │  ├─ 3
    # │  │  └─ 3
    # │  └─ 2
    # │     ├─ 3
    # │     └─ 3
    # └─ 1
    #    ├─ 2
    #    │  ├─ 3
    #    │  └─ 3
    #    └─ 2
    #       ├─ 3
    #       └─ 3
    #

    for maxdepth in [3,5,8]
        buffer = IOBuffer()
        print_tree(buffer, Num(0), maxdepth)
        ptxt = String(take!(buffer))
        n1  = sum([1 for c in ptxt if c=="$(maxdepth-1)"[1]])
        n2  = sum([1 for c in ptxt if c=="$maxdepth"[1]])
        n3  = sum([1 for c in ptxt if c=="$(maxdepth+1)"[1]])
        @test n1==2^(maxdepth-1)
        @test n2==2^maxdepth
        @test n3==0
    end

    # test that `print_tree(headnode)` prints truncation characters under each
    # node at the default maxdepth level = 5
    truncation_char = AbstractTrees.TreeCharSet().trunc
    buffer = IOBuffer()
    print_tree(buffer, Num(0))
    ptxt = String(take!(buffer))
    n1  = sum([1 for c in ptxt if c=='5'])
    n2  = sum([1 for c in ptxt if c=='6'])
    n3  = sum([1 for c in ptxt if c==truncation_char])
    @test n1==2^5
    @test n2==0
    @test n3==2^5
    lines = split(ptxt, '\n')
    for i in 1:length(lines)
        if ~isempty(lines[i]) && lines[i][end] == '5'
            @test lines[i+1][end] == truncation_char
        end
    end

    # test correct number of lines printed 1
    buffer = IOBuffer()
    print_tree(buffer, SingleChildInfiniteDepth())
    ptxt = String(take!(buffer))
    numlines = sum([1 for c in split(ptxt, '\n') if ~isempty(strip(c))])
    @test numlines == 7 # 1 (head node) + 5 (default depth) + 1 (truncation char)

    # test correct number of lines printed 2
    buffer = IOBuffer()
    print_tree(buffer, SingleChildInfiniteDepth(), 3)
    ptxt = String(take!(buffer))
    numlines = sum([1 for c in split(ptxt, '\n') if ~isempty(strip(c))])
    @test numlines == 5 # 1 (head node) + 3 (depth) + 1 (truncation char)

    # test correct number of lines printed 3
    buffer = IOBuffer()
    print_tree(buffer, SingleChildInfiniteDepth(), 3, indicate_truncation=false)
    ptxt = String(take!(buffer))
    numlines = sum([1 for c in split(ptxt, '\n') if ~isempty(strip(c))])
    @test numlines == 4 # 1 (head node) + 3 (depth)
end
