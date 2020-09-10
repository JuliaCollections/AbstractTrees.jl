# Test implementation for builtin types


@testset "Array" begin
    tree = Any[1,Any[2,3]]

    T = Vector{Any}  # This is printed as "Array{Any,1}" in older versions of Julia
    @test repr_tree(tree) == "$T\n├─ 1\n└─ $T\n   ├─ 2\n   └─ 3\n"

    @test collect(Leaves(tree)) == [1,2,3]
    @test collect(Leaves(tree)) isa Vector{Int}
    @test collect(PostOrderDFS(tree)) == Any[1,2,3,Any[2,3],Any[1,Any[2,3]]]
    @test collect(StatelessBFS(tree)) == Any[Any[1,Any[2,3]],1,Any[2,3],2,3]

    tree2 = Any[Any[1,2],Any[3,4]]
    @test collect(PreOrderDFS(tree2)) == Any[tree2,Any[1,2],1,2,Any[3,4],3,4]
end
