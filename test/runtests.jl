using AbstractTrees
using AbstractTrees: repr_tree
using Test
import Base: ==


@testset "Builtins" begin include("builtins.jl") end
@testset "Custom tree types" begin include("trees.jl") end
#@testset "Printing" begin include("printing.jl") end

#TODO: add separate tests for printing
