using AbstractTrees, Test
using Aqua

@testset "Builtins" begin include("builtins.jl") end
@testset "Custom tree types" begin include("trees.jl") end
if Base.VERSION >= v"1.6"
    # Printing tests use `findall` variants that are not supported on Julia 1.0
    @testset "Printing" begin include("printing.jl") end
end

Aqua.test_all(AbstractTrees)