using Documenter, AbstractTrees

makedocs(
    modules = [AbstractTrees],
    sitename = "AbstractTrees.jl",
    authors = "Keno Fischer",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
        "Home" => "index.md",
        "Iteration" => "iteration.md",
        "Internals" => "internals.md",
        "FAQ" => "faq.md",
    ],
)

deploydocs(
    repo = "github.com/JuliaCollections/AbstractTrees.jl.git",
)
