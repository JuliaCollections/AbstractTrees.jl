"""
    print_tree(tree; kwargs...)
    print_tree(io::IO, tree; kwargs...)
    print_tree(f::Function, io::IO, tree; kwargs...)

Print a text representation of `tree` to the given `io` object.

# Arguments

* `f::Function` - custom implementation of [`printnode`](@ref) to use. Should have the
  signature `f(io::IO, node)`.
* `maxdepth::Integer = 5` - truncate printing of subtrees at this depth.
* `indicate_truncation::Bool = true` - print a vertical ellipsis character beneath
  truncated nodes.
* `charset::TreeCharSet` - [`TreeCharSet`](@ref) to use to print branches.

# Examples

```jldoctest; setup = :(using AbstractTrees)
julia> tree = [1:3, "foo", [[[4, 5], 6, 7], 8]];

julia> print_tree(tree)
Array{Any,1}
├─ UnitRange{Int64}
│  ├─ 1
│  ├─ 2
│  └─ 3
├─ "foo"
└─ Array{Any,1}
   ├─ Array{Any,1}
   │  ├─ Array{Int64,1}
   │  │  ├─ 4
   │  │  └─ 5
   │  ├─ 6
   │  └─ 7
   └─ 8

julia> print_tree(tree, maxdepth=2)
Array{Any,1}
├─ UnitRange{Int64}
│  ├─ 1
│  ├─ 2
│  └─ 3
├─ "foo"
└─ Array{Any,1}
   ├─ Array{Any,1}
   │  ⋮
   │
   └─ 8

julia> print_tree(tree, charset=AbstractTrees.ASCII_CHARSET)
Array{Any,1}
+-- UnitRange{Int64}
|   +-- 1
|   +-- 2
|   \\-- 3
+-- "foo"
\\-- Array{Any,1}
    +-- Array{Any,1}
    |   +-- Array{Int64,1}
    |   |   +-- 4
    |   |   \\-- 5
    |   +-- 6
    |   \\-- 7
    \\-- 8
```

"""
print_tree


"""
    printnode(io::IO, node)

Print a compact representation of a single node.
"""
printnode(io::IO, node) = show(IOContext(io, :compact => true, :limit => true), node)


"""
    repr_node(node; context=nothing)

Get the string representation of a node using [`printnode`](@ref). This works
analagously to `Base.repr`.

`context` is an `IO` or `IOContext` object whose attributes are used for the
I/O stream passed to `printnode`.
"""
function repr_node(node; context=nothing)
    buf = IOBuffer()
    io = context === nothing ? buf : IOContext(buf, context)
    printnode(io, node)
    return String(take!(buf))
end


"""
    TreeCharSet

Set of characters (or strings) used to pretty-print tree branches in
[`print_tree`](@ref).
"""
struct TreeCharSet
    mid
    terminator
    skip
    dash
    trunc
end

"""Default `charset` argument used by [`print_tree`](@ref)."""
const DEFAULT_CHARSET = TreeCharSet('├', '└', '│', '─', '⋮')
"""Charset using only ASCII characters."""
const ASCII_CHARSET = TreeCharSet("+", "\\", "|", "--", "...")

function TreeCharSet()
    Base.depwarn("The 0-argument constructor of TreeCharSet is deprecated, use AbstractTrees.DEFAULT_CHARSET instead.", :TreeCharSet)
    return DEFAULT_CHARSET
end


"""
Print tree branches in the initial part of a [`print_tree`](@ref) line, before
the node itself is printed.
"""
function print_prefix(io::IO, depth::Int, charset::TreeCharSet, active_levels)
    for current_depth in 0:(depth-1)
        if current_depth in active_levels
            print(io,charset.skip," "^(textwidth(charset.dash)+1))
        else
            print(io," "^(textwidth(charset.skip)+textwidth(charset.dash)+1))
        end
    end
end

function _print_tree(printnode::Function, io::IO, tree; maxdepth = 5, indicate_truncation = true,
                     depth = 0, active_levels = Int[], charset = DEFAULT_CHARSET, withinds = false,
                     inds = [], roottree = tree)

    # Print node representation

    # Temporary buffer to write to
    nodebuf = IOBuffer()
    # Copy IOContext to buffer
    isa(io, IOContext) && (nodebuf = IOContext(nodebuf, io))

    # Print node representation into buffer
    if withinds
        printnode(nodebuf, tree, inds)
    elseif tree != roottree && isa(treekind(roottree), IndexedTree)
        printnode(nodebuf, roottree[tree])
    else
        printnode(nodebuf, tree)
    end
    str = String(take!(isa(nodebuf, IOContext) ? nodebuf.io : nodebuf))

    # Copy buffer to output, prepending prefix to each line
    for (i, line) in enumerate(split(str, '\n'))
        i != 1 && print_prefix(io, depth, charset, active_levels)
        println(io, line)
    end

    c = isa(treekind(roottree), IndexedTree) ? childindices(roottree, tree) : children(roottree, tree)

    # No children
    c === () && return

    # Reached max depth
    if depth >= maxdepth
        # Print truncation char(s)
        if indicate_truncation
            print_prefix(io, depth, charset, active_levels)
            println(io, charset.trunc)
            print_prefix(io, depth, charset, active_levels)
            println(io)
        end

        return
    end

    # Children or key => child pairs to print
    it = withinds ? pairs(c) : c
    s = Iterators.Stateful(it)

    # Print children
    while !isempty(s)
        if withinds
            ind, child = popfirst!(s)
        else
            child = popfirst!(s)
        end

        print_prefix(io, depth, charset, active_levels)

        # Last child?
        if isempty(s)
            print(io, charset.terminator)
            child_active_levels = active_levels
        else
            print(io, charset.mid)
            child_active_levels = vcat(active_levels, depth)
        end

        print(io, charset.dash, ' ')

        _print_tree(printnode, io, child; maxdepth=maxdepth,
            indicate_truncation=indicate_truncation, depth=depth + 1,
            active_levels=child_active_levels, charset=charset, withinds=withinds,
            inds=withinds ? [inds; ind] : [], roottree=roottree)
    end
end

print_tree(f::Function, io::IO, tree; kwargs...) = _print_tree(f, io, tree; kwargs...)

function print_tree(f::Function, io::IO, tree, maxdepth; kwargs...)
    Base.depwarn("Passing maxdepth as a positional argument is deprecated, use as a keyword argument instead.", :print_tree)
    print_tree(f, io, tree; maxdepth=maxdepth, kwargs...)
end

print_tree(io::IO, tree, args...; kwargs...) = print_tree(printnode, io, tree, args...; kwargs...)
print_tree(tree, args...; kwargs...) = print_tree(stdout::IO, tree, args...; kwargs...)



"""
    repr_tree(tree; context=nothing, kw...)

Get the string result of calling [`print_tree`](@ref) with the supplied arguments.

The `context` argument works as it does in `Base.repr`.
"""
function repr_tree(tree, args...; context=nothing, kw...)
    buf = IOBuffer()
    io = context === nothing ? buf : IOContext(buf, context)
    print_tree(io, tree, args...; kw...)
    return String(take!(buf))
end
