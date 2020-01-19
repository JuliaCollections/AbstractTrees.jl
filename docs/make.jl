using Documenter, AbstractTrees


makedocs(
    modules = [AbstractTrees],
    sitename = "AbstractTrees.jl",
    authors = "Keno Fischer",
    pages = [
        "index.md",
        "api.md",
    ],
)
