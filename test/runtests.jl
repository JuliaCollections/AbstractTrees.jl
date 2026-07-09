using AbstractTrees, Test
using Aqua

if applicable(parentmodule, which(sin, Tuple{Float64})::Method)
    # tests use `parentmodule(::Method)`, only supported on v1.10 and up
    @testset "Traits" begin include("traits.jl") end
end
@testset "Builtins" begin include("builtins.jl") end
@testset "Custom tree types" begin include("trees.jl") end
if Base.VERSION >= v"1.6"
    # Printing tests use `findall` variants that are not supported on Julia 1.0
    @testset "Printing" begin include("printing.jl") end
end

Aqua.test_all(AbstractTrees)