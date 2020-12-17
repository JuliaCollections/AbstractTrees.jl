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

```julia
julia> print_tree(stdout, Dict("a"=>"b","b"=>['c','d']))
Dict{String,Any}("b"=>['c','d'],"a"=>"b")
├─ b
│  ├─ c
│  └─ d
└─ a
   └─ b

julia> print_tree(stdout, '0'=>'1'=>'2'=>'3', 2)
'0'
└─ '1'
    └─ '2'
        ⋮

julia> print_tree(stdout, Dict("a"=>"b","b"=>['c','d']);
        charset = TreeCharSet('+','\\\\','|',"--","⋮"))
Dict{String,Any}("b"=>['c','d'],"a"=>"b")
+-- b
|   +-- c
|   \\-- d
\\-- a
   \\-- b
```

"""
print_tree


"""
    printnode(io::IO, node)

Print a single node. The default is to show a compact representation of `node`.
Override this if you want nodes printed in a custom way in [`print_tree`](@ref),
or if you want your print function to print part of the tree by default.

# Examples

```
struct MyNode{T}
    data::T
    children::Vector{MyNode{T}}
end
AbstractTrees.printnode(io::IO, node::MyNode) = print(io, "MyNode(\$(node.data))")
```
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
                     inds = [], from = nothing, to = nothing, roottree = tree)
    nodebuf = IOBuffer()
    isa(io, IOContext) && (nodebuf = IOContext(nodebuf, io))
    if withinds
        printnode(nodebuf, tree, inds)
    else
        tree != roottree && isa(treekind(roottree), IndexedTree) ?
            printnode(nodebuf, roottree[tree]) :
            printnode(nodebuf, tree)
    end
    str = String(take!(isa(nodebuf, IOContext) ? nodebuf.io : nodebuf))
    for (i,line) in enumerate(split(str, '\n'))
        i != 1 && print_prefix(io, depth, charset, active_levels)
        println(io, line)
    end
    c = isa(treekind(roottree), IndexedTree) ?
        childindices(roottree, tree) : children(roottree, tree)
    if c !== ()
        if depth < maxdepth
            s = Iterators.Stateful(from === nothing ? pairs(c) : Iterators.Rest(pairs(c), from))
            while !isempty(s)
                ind, child = popfirst!(s)
                ind === to && break
                active = false
                child_active_levels = active_levels
                print_prefix(io, depth, charset, active_levels)
                if isempty(s)
                    print(io, charset.terminator)
                else
                    print(io, charset.mid)
                    child_active_levels = push!(copy(active_levels), depth)
                end
                print(io, charset.dash, ' ')
                print_tree(printnode, io, child; maxdepth=maxdepth,
                indicate_truncation=indicate_truncation, depth = depth + 1,
                active_levels = child_active_levels, charset = charset, withinds=withinds,
                inds = withinds ? [inds; ind] : [], roottree = roottree)
            end
        elseif indicate_truncation
            print_prefix(io, depth, charset, active_levels)
            println(io, charset.trunc)
            print_prefix(io, depth, charset, active_levels)
            println(io)
        end
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
