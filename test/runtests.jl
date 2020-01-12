using AbstractTrees
using Test
import Base: ==

if VERSION >= v"1.1.0-DEV.838" # requires https://github.com/JuliaLang/julia/pull/30291
    @testset "Ambiguities" begin
        @test isempty(detect_ambiguities(AbstractTrees, Base, Core))
    end
end

AbstractTrees.children(x::Array) = x
tree = Any[1,Any[2,3]]

@testset "Array" begin
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

ot = OneTree([2,3,4,0])

@testset "OneTree" begin
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

pt = ParentTree(ot,[0,1,2,3])
@testset "ParentTree" begin
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

itree = IntTree(1, [IntTree(2, IntTree[])])
Base.eltype(::Type{<:TreeIterator{IntTree}}) = IntTree
Base.IteratorEltype(::Type{<:TreeIterator{IntTree}}) = Base.HasEltype()
AbstractTrees.nodetype(::IntTree) = IntTree
iter = Leaves(itree)
@testset "IntTree" begin
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
end  # @testset "Examples"
