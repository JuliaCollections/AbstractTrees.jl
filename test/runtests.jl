using AbstractTrees, Test


@testset "Builtins" begin include("builtins.jl") end
@testset "Custom tree types" begin include("trees.jl") end
@testset "Printing" begin include("printing.jl") end

