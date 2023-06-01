# AbstractTrees

[![Build Status](https://github.com/JuliaCollections/AbstractTrees.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaCollections/AbstractTrees.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/JuliaCollections/AbstractTrees.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaCollections/AbstractTrees.jl)

[![][docs-stable-img]][docs-stable-url] [![][docs-latest-img]][docs-latest-url]

A package for dealing with generalized tree-like data structures.

## Examples
```julia
julia> t = [[1,2], [3,4]];  # AbstractArray and AbstractDict are trees

julia> children(t)
2-element Vector{Vector{Int64}}:
 [1, 2]
 [3, 4]

julia> getdescendant(t, (2,1))
3

julia> collect(PreOrderDFS(t))  # iterate from root to leaves
7-element Vector{Any}:
  [[1, 2], [3, 4]]
  [1, 2]
 1
 2
  [3, 4]
 3
 4

julia> collect(PostOrderDFS(t))  # iterate from leaves to root
7-element Vector{Any}:
 1
 2
  [1, 2]
 3
 4
  [3, 4]
  [[1, 2], [3, 4]]

julia> collect(Leaves(t))  # iterate over leaves
4-element Vector{Int64}:
 1
 2
 3
 4

julia> struct FloatTree  # make your own trees
        x::Float64
        children::Vector{FloatTree}
    end;

julia> AbstractTrees.children(t::FloatTree) = t.children;

julia> AbstractTrees.nodevalue(t::FloatTree) = t.x;

julia> print_tree(FloatTree(NaN, [FloatTree(Inf, []), FloatTree(-Inf, [])]))
NaN
├─ Inf
└─ -Inf
```

## Related Packages

- [D3Trees.jl](https://github.com/sisl/D3Trees.jl) provides interactive rendering of large trees using the D3.js javascript package.

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://JuliaCollections.github.io/AbstractTrees.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://JuliaCollections.github.io/AbstractTrees.jl/stable

