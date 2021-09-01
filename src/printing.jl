"""
    print_tree(tree; kwargs...)
    print_tree(io::IO, tree; kwargs...)
    print_tree(f::Function, io::IO, tree; kwargs...)

Print a text representation of `tree` to the given `io` object.

# Arguments

* `f::Function` - custom implementation of [`printnode`](@ref) to use. Should have the
  signature `f(io::IO, node)`.
* `io::IO` - IO stream to write to.
* `tree` - tree to print.
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


const _CharArg = Union{AbstractString, Char}

"""
    TreeCharSet

Set of characters (or strings) used to pretty-print tree branches in [`print_tree`](@ref).
"""
struct TreeCharSet
    mid::String
    terminator::String
    skip::String
    dash::String
    trunc::String

    function TreeCharSet(mid::_CharArg, terminator::_CharArg, skip::_CharArg, dash::_CharArg, trunc::_CharArg)
        return new(String(mid), String(terminator), String(skip), String(dash), String(trunc))
    end
end

"""Default `charset` argument used by [`print_tree`](@ref)."""
const DEFAULT_CHARSET = TreeCharSet("├", "└", "│", "─", "⋮")
"""Charset using only ASCII characters."""
const ASCII_CHARSET = TreeCharSet("+", "\\", "|", "--", "...")

function TreeCharSet()
    Base.depwarn("The 0-argument constructor of TreeCharSet is deprecated, use AbstractTrees.DEFAULT_CHARSET instead.", :TreeCharSet)
    return DEFAULT_CHARSET
end


function _print_tree(printnode::Function,
                     io::IO,
                     tree;
                     maxdepth::Int,
                     indicate_truncation::Bool,
                     charset::TreeCharSet,
                     roottree = tree,
                     depth::Int = 0,
                     prefix::String = "",
                     )

    # Print node representation

    # Get node representation as string
    toprint = tree != roottree && isa(treekind(roottree), IndexedTree) ? roottree[tree] : tree
    str = repr_node(toprint, context=io)

    # Copy buffer to output, prepending prefix to each line
    for (i, line) in enumerate(split(str, '\n'))
        i != 1 && print(io, prefix)
        println(io, line)
    end

    c = isa(treekind(roottree), IndexedTree) ? childindices(roottree, tree) : children(roottree, tree)

    # No children?
    isempty(c) && return

    # Reached max depth
    if depth >= maxdepth
        # Print truncation char(s)
        if indicate_truncation
            println(io, prefix, charset.trunc)
            println(io, prefix)
        end

        return
    end

    # Print children
    s = Iterators.Stateful(c)

    while !isempty(s)
        child = popfirst!(s)
        child_prefix = prefix

        print(io, prefix)

        # Last child?
        if isempty(s)
            print(io, charset.terminator)
            child_prefix *= " " ^ (textwidth(charset.skip) + textwidth(charset.dash) + 1)
        else
            print(io, charset.mid)
            child_prefix *= charset.skip * " " ^ (textwidth(charset.dash) + 1)
        end

        print(io, charset.dash, ' ')

        _print_tree(printnode, io, child;
            maxdepth=maxdepth, indicate_truncation=indicate_truncation, charset=charset,
            roottree=roottree, depth=depth + 1, prefix=child_prefix)
    end
end

function print_tree(f::Function,
                    io::IO,
                    tree;
                    maxdepth::Int = 5,
                    indicate_truncation::Bool = true,
                    charset::TreeCharSet = DEFAULT_CHARSET,
                    )
    _print_tree(f, io, tree; maxdepth=maxdepth, indicate_truncation=indicate_truncation, charset=charset)
end

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
