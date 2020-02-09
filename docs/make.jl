using Documenter, AbstractTrees

makedocs(
    modules = [AbstractTrees],
    sitename = "AbstractTrees.jl",
    authors = "Keno Fischer",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
        "index.md",
        "api.md",
    ],
)

deploydocs(
    repo = "github.com/JuliaCollections/AbstractTrees.jl.git",
)
