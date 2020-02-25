"""
    print_tree(tree, maxdepth=5; kwargs...)
    print_tree(io, tree, maxdepth=5; kwargs...)
    print_tree(f::Function, io, tree, maxdepth=5; kwargs...)

# Usage
Prints an ASCII formatted representation of the `tree` to the given `io` object.
By default all children will be printed up to a maximum level of 5, though this
value can be overriden by the `maxdepth` parameter. Nodes that are truncated are
indicated by a vertical ellipsis below the truncated node, this indication can be
turned off by providing `indicate_truncation=false` as a kwarg. The charset to use in
printing can be customized using the `charset` keyword argument.
You can control the printing of individual nodes by passing a function `f(io, node)`;
the default is [`AbstractTrees.printnode`](@ref).

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
        charset = TreeCharSet('+','\\','|',"--","⋮"))
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

# Example

```
struct MyNode{T}
    data::T
    children::Vector{MyNode{T}}
end
AbstractTrees.printnode(io::IO, node::MyNode) = print(io, "MyNode(\$(node.data))")
```
"""
printnode(io::IO, node) = show(IOContext(io, :compact => true), node)


struct TreeCharSet
    mid
    terminator
    skip
    dash
    trunc
end

# Default charset
TreeCharSet() = TreeCharSet('├','└','│','─','⋮')
TreeCharSet(mid, term, skip, dash) = TreeCharSet(mid, term, skip, dash, '⋮')


function print_prefix(io, depth, charset, active_levels)
    for current_depth in 0:(depth-1)
        if current_depth in active_levels
            print(io,charset.skip," "^(textwidth(charset.dash)+1))
        else
            print(io," "^(textwidth(charset.skip)+textwidth(charset.dash)+1))
        end
    end
end

function _print_tree(printnode::Function, io::IO, tree, maxdepth = 5; indicate_truncation = true,
                     depth = 0, active_levels = Int[], charset = TreeCharSet(), withinds = false,
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
                print_tree(printnode, io, child, maxdepth;
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
print_tree(f::Function, io::IO, tree, args...; kwargs...) = _print_tree(f, io, tree, args...; kwargs...)
print_tree(io::IO, tree, args...; kwargs...) = print_tree(printnode, io, tree, args...; kwargs...)
print_tree(tree, args...; kwargs...) = print_tree(stdout::IO, tree, args...; kwargs...)
