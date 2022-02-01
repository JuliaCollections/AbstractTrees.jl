using AbstractTrees
using AbstractTrees: repr_tree
using Test
import Base: ==


if v"1.1.0" < VERSION # requires https://github.com/JuliaLang/julia/pull/30291
    @testset "Ambiguities" begin
        if  VERSION < v"1.8-"
            @test isempty(detect_ambiguities(AbstractTrees, Base, Core))
        else
            @test_broken isempty(detect_ambiguities(AbstractTrees, Base, Core))
        end
    end
end


@testset "Builtins" begin include("builtins.jl") end
@testset "Custom tree types" begin include("trees.jl") end
@testset "Printing" begin include("printing.jl") end
@testset "Examples" begin include("examples.jl") end
