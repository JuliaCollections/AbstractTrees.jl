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
* `printkeys::Union{Bool, Nothing}` - Whether to print keys of child nodes (using
  `pairs(children(node))`). A value of `nothing` uses [`printkeys_default`](@ref) do decide the
  behavior on a node-by-node basis.

# Examples

```jldoctest; setup = :(using AbstractTrees)
julia> tree = [1:3, "foo", [[[4, 5], 6, 7], 8]];

julia> print_tree(tree)
Vector{Any}
├─ UnitRange{Int64}
│  ├─ 1
│  ├─ 2
│  └─ 3
├─ "foo"
└─ Vector{Any}
   ├─ Vector{Any}
   │  ├─ Vector{Int64}
   │  │  ├─ 4
   │  │  └─ 5
   │  ├─ 6
   │  └─ 7
   └─ 8

julia> print_tree(tree, maxdepth=2)
Vector{Any}
├─ UnitRange{Int64}
│  ├─ 1
│  ├─ 2
│  └─ 3
├─ "foo"
└─ Vector{Any}
   ├─ Vector{Any}
   │  ⋮
   │
   └─ 8

julia> print_tree(tree, charset=AbstractTrees.ASCII_CHARSET)
Vector{Any}
+-- UnitRange{Int64}
|   +-- 1
|   +-- 2
|   \\-- 3
+-- "foo"
\\-- Vector{Any}
    +-- Vector{Any}
    |   +-- Vector{Int64}
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
    TreeCharSet(mid, terminator, skip, dash, trunc, pair)

Set of characters (or strings) used to pretty-print tree branches in [`print_tree`](@ref).

# Fields

* `mid::String` - "Forked" branch segment connecting to middle children.
* `terminator::String` - Final branch segment connecting to last child.
* `skip::String` - Vertical branch segment.
* `dash::String` - Horizontal branch segmentt printed to the right of `mid` and `terminator`.
* `trunc::String` - Used to indicate the subtree has been truncated at the maximum depth.
* `pair::String` - Printed between a child node and its key.
"""
struct TreeCharSet
    mid::String
    terminator::String
    skip::String
    dash::String
    trunc::String
    pair::String

    function TreeCharSet(mid::_CharArg, terminator::_CharArg, skip::_CharArg, dash::_CharArg, trunc::_CharArg, pair::_CharArg)
        return new(String(mid), String(terminator), String(skip), String(dash), String(trunc), String(pair))
    end
end

"""
    TreeCharSet(base::TreeCharSet; fields...)

Create a new `TreeCharSet` by modifying select fields of an existing instance.
"""
function TreeCharSet(base::TreeCharSet;
                     mid = base.mid,
                     terminator = base.terminator,
                     skip = base.skip,
                     dash = base.dash,
                     trunc = base.trunc,
                     pair = base.pair,
                     )
    return TreeCharSet(mid, terminator, skip, dash, trunc, pair)
end

"""Default `charset` argument used by [`print_tree`](@ref)."""
const DEFAULT_CHARSET = TreeCharSet("├", "└", "│", "─", "⋮", " => ")
"""Charset using only ASCII characters."""
const ASCII_CHARSET = TreeCharSet("+", "\\", "|", "--", "...", " => ")

function TreeCharSet()
    Base.depwarn("The 0-argument constructor of TreeCharSet is deprecated, use AbstractTrees.DEFAULT_CHARSET instead.", :TreeCharSet)
    return DEFAULT_CHARSET
end


"""
    printkeys_default(children)::Bool

Whether a collection of children should be printed with its keys by default.

The base behavior is to print keys for all collections for which `keys()` is defined, with the
exception of `AbstractVector`s and tuples.
"""
printkeys_default(children) = applicable(keys, children)
printkeys_default(children::AbstractVector) = false
printkeys_default(children::Tuple) = false


"""
    print_child_key(io::IO, key)

Print the key for a child node.
"""
print_child_key(io::IO, key) = show(io, key)
print_child_key(io::IO, key::CartesianIndex) = show(io, Tuple(key))


function _print_tree(printnode::Function,
                     io::IO,
                     tree;
                     maxdepth::Int,
                     indicate_truncation::Bool,
                     charset::TreeCharSet,
                     printkeys::Union{Bool, Nothing},
                     roottree = tree,
                     depth::Int = 0,
                     prefix::String = "",
                     )
    if roottree === tree && depth == 0 && isa(treekind(tree), IndexedTree)
        roottree = Indexed(roottree)
        tree = rootindex(roottree.tree)
    end

    # Print node representation

    # Get node representation as string
    toprint = tree !== roottree && isa(treekind(roottree), IndexedTree) ? roottree[tree] : tree
    str = repr_node(toprint, context=io)

    # Copy buffer to output, prepending prefix to each line
    for (i, line) in enumerate(split(str, '\n'))
        i != 1 && print(io, prefix)
        println(io, line)
    end

    # Node children
    c = children(roottree, tree)

    # No children?
    isempty(c) && return

    # Reached max depth?
    if depth >= maxdepth
        # Print truncation char(s)
        if indicate_truncation
            println(io, prefix, charset.trunc)
            println(io, prefix)
        end

        return
    end

    # Print keys?
    this_printkeys = applicable(keys, c) && (printkeys === nothing ? printkeys_default(c) : printkeys)

    # Print children
    s = Iterators.Stateful(this_printkeys ? pairs(c) : c)

    while !isempty(s)
        child_prefix = prefix

        if this_printkeys
            child_key, child = popfirst!(s)
        else
            child = popfirst!(s)
            child_key = nothing
        end

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

        # Print key
        if this_printkeys
            buf = IOBuffer()
            print_child_key(IOContext(buf, io), child_key)
            key_str = String(take!(buf))

            print(io, key_str, charset.pair)

            child_prefix *= " " ^ (textwidth(key_str) + textwidth(charset.pair))
        end

        _print_tree(printnode, io, child;
            maxdepth=maxdepth, indicate_truncation=indicate_truncation, charset=charset,
            printkeys=printkeys, roottree=roottree, depth=depth + 1, prefix=child_prefix)
    end
end

function print_tree(f::Function,
                    io::IO,
                    tree;
                    maxdepth::Int = 5,
                    indicate_truncation::Bool = true,
                    charset::TreeCharSet = DEFAULT_CHARSET,
                    printkeys::Union{Bool, Nothing} = nothing,
                    )
    _print_tree(f, io, tree; maxdepth=maxdepth, indicate_truncation=indicate_truncation, charset=charset, printkeys=printkeys)
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
function repr_tree(tree; context=nothing, kw...)
    buf = IOBuffer()
    io = context === nothing ? buf : IOContext(buf, context)
    print_tree(io, tree; kw...)
    return String(take!(buf))
end
