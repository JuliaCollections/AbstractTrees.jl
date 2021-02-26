# Test implementation for builtin types
using AbstractTrees
using AbstractTrees: repr_tree
using Test

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


@testset "Expr" begin
    expr = :(foo(x^2 + 3))

    @test children(expr) == expr.args

    @test repr_tree(expr) == "Expr(:call)\n├─ :foo\n└─ Expr(:call)\n   ├─ :+\n   ├─ Expr(:call)\n   │  ├─ :^\n   │  ├─ :x\n   │  └─ 2\n   └─ 3\n"

    @test collect(Leaves(expr)) == [:foo, :+, :^, :x, 2, 3]
end

if Base.VERSION >= v"1.6.0-DEV.1594"
    # Much of this is taken from julia/test/compiler/inference.jl
    @testset "Core.Compiler.Timings" begin
        matches(rex, str) = match(rex, str) !== nothing
        function time_inference(f)
            Core.Compiler.Timings.reset_timings()
            Core.Compiler.__set_measure_typeinf(true)
            f()
            Core.Compiler.__set_measure_typeinf(false)
            Core.Compiler.Timings.close_current_timer()
            return Core.Compiler.Timings._timings[1]
        end
        function eval_module()
            @eval module AbstractTreesTestInferenceTiming
                i(x) = x+5
                i2(x) = x+2
                h(a::Array) = i2(a[1]::Integer) + i(a[1]::Integer) + 2
                g(y::Integer, x) = h(Any[y]) + Int(x)
            end
        end
        # Define and make sure all "underlying" functions are compiled
        eval_module()
        AbstractTreesTestInferenceTiming.g(2, 3.0)
        # Now do the real test with a freshly-evaluated module
        eval_module()
        tinf = time_inference() do
            @eval AbstractTreesTestInferenceTiming.g(2, 3.0)
        end
        io = IOBuffer()
        print_tree(io, tinf)
        strs = split(chomp(String(take!(io))), '\n')
        rexf = "[0-9]*\\.?[0-9]*"
        thismod = "$(@__MODULE__)"
        @test any(strs) do str
            matches(Regex("$(rexf)ms: InferenceFrameInfo for Core\\.Compiler\\.Timings\\.ROOT\\(\\)"), str)
        end
        @test any(strs) do str
            matches(Regex("├─ $(rexf)ms: InferenceFrameInfo for $(thismod)\\.AbstractTreesTestInferenceTiming\\.g\\(::$Int, ::Float64\\)"), str)
        end
        @test any(strs) do str
            matches(Regex("│  └─ $(rexf)ms: InferenceFrameInfo for $(thismod)\\.AbstractTreesTestInferenceTiming\\.h\\(::Vector{Any}\\)"), str)
        end
        @test any(strs) do str
            matches(Regex("├─ $(rexf)ms: InferenceFrameInfo for $(thismod)\\.AbstractTreesTestInferenceTiming\\.i2\\(::Integer\\)"), str)
        end
        @test any(strs) do str
            matches(Regex("[└├]─ $(rexf)ms: InferenceFrameInfo for $(thismod)\\.AbstractTreesTestInferenceTiming\\.i\\(::Integer\\)"), str)
        end
        # These two do not have the pipe characters because we aren't sure which will be last
        @test any(strs) do str
            matches(Regex("$(rexf)ms: InferenceFrameInfo for $(thismod)\\.AbstractTreesTestInferenceTiming\\.i2\\(::$Int\\)"), str)
        end
        @test any(strs) do str
            matches(Regex("$(rexf)ms: InferenceFrameInfo for $(thismod)\\.AbstractTreesTestInferenceTiming\\.i\\(::$Int\\)"), str)
        end
    end
end
