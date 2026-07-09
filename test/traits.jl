module TestTraits

using AbstractTrees
using Test

function is_owned_by(m::Module, n::Module)
    ret = false
    while m != Main
        if m == n
            ret = true
            break
        end
        m = parentmodule(m)
    end
    ret
end

function is_owned_by(m::Method, n::Module)
    is_owned_by(parentmodule(m), n)
end

function we_own_the_method(m::Method)
    is_owned_by(m, AbstractTrees)
end

const traits = (
    ParentLinks, SiblingLinks, ChildIndexing, childrentype, childtype, AbstractTrees.childstatetype, NodeType, nodetype,
)

const base_traits = (
    eltype, Base.IteratorEltype,
)

struct T end

for func ∈ traits
    f = nameof(func)
    @eval begin
        function AbstractTrees.$f(::Type{<:T})
            # This method should not ever get called, it just serves to test dispatch/type piracy.
            throw(ArgumentError("this is not the method you're looking for"))
        end
    end
end

for func ∈ base_traits
    f = nameof(func)
    @eval begin
        function Base.$f(::Type{<:AbstractTrees.TreeIterator{<:T}})
            # This method should not ever get called, it just serves to test dispatch/type piracy.
            throw(ArgumentError("this is not the method you're looking for"))
        end
    end
end

@testset "Traits" begin
    @testset "traits should not make dependents vulnerable to commiting type piracy" begin
        @testset "AbstractTrees traits" begin
            @testset "func: $func" for func ∈ traits
                arg = Union{}
                @test_throws Exception func(arg)
                @test all(we_own_the_method, methods(func, Tuple{Type{arg}}))
            end
        end
        @testset "Base traits" begin
            @testset "func: $func" for func ∈ base_traits
                arg = AbstractTrees.TreeIterator{Union{}}
                @test_throws Exception func(arg)
                @test all(we_own_the_method, methods(func, Tuple{Type{arg}}))
            end
        end
    end
end

end
