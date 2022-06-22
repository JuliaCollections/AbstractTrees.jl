# Ensure that we can run all files in the examples directory with no errors.
# Note: fstree doesn't work on Julia 1.0

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
