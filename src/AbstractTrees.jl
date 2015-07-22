module AbstractTrees

export print_tree, TreeCharSet

# This package is intended to provide an abstract interface for working.
# Though the package itself is not particularly sophisticated, it defines
# the interface that can be used by other packages to talk about trees.

# By default assume that if an object is iterable, it's iteration gives the
# children. If an object is not iterable, assume it does not have children by
# default.
function children(x)
    if applicable(start, x) && !isa(x, Integer) && !isa(x, Char)
        return x
    else
        return ()
    end
end
has_children(x) = children(x) !== ()

# Print a single node. Override this if you want your print function to print
# part of the tree by default
printnode(io::IO, node) = print(io,node)

# Special cases

# Don't consider strings tree-iterable in general
children(x::AbstractString) = ()

# To support iteration over associatives, define printnode on Tuples to return
# the first element. If this doesn't work well in practice it may be better to
# create a special iterator that `children` on `Associative` returns.
# Even better, iteration over associatives should return pairs.

printnode{K,V}(io::IO, kv::Tuple{K,V}) = printnode(io,kv[1])
children{K,V}(kv::Tuple{K,V}) = kv[2]

# Utilities

# Printing
immutable TreeCharSet
    mid
    terminator
    skip
    dash
end

# Default charset
TreeCharSet() = TreeCharSet('├','└','│','─')

_charwidth(c::Char) = charwidth(c)
_charwidth(s) = sum(map(charwidth,collect(s)))

function print_prefix(io, depth, charset, active_levels)
    for current_depth in 0:(depth-1)
        if current_depth in active_levels
            print(io,charset.skip," "^(_charwidth(charset.dash)+1))
        else
            print(io," "^(_charwidth(charset.skip)+_charwidth(charset.dash)+1))
        end
    end
end

"""
# Usage
Prints an ASCII formatted representation of the `tree` to the given `io` object.
By default all children will be printed up to a maximum level of 5, though this
valud can be overriden by the `maxdepth` parameter. The charset to use in
printing can be customized using the `charset` keyword argument.

# Examples
```julia
julia> print_tree(STDOUT,Dict("a"=>"b","b"=>['c','d']))
Dict{ASCIIString,Any}("b"=>['c','d'],"a"=>"b")
├─ b
│  ├─ c
│  └─ d
└─ a
   └─ b

julia> print_tree(STDOUT,Dict("a"=>"b","b"=>['c','d']);
        charset = TreeCharSet('+','\\','|',"--"))
Dict{ASCIIString,Any}("b"=>['c','d'],"a"=>"b")
+-- b
|   +-- c
|   \-- d
\-- a
   \-- b
```

"""
function print_tree(io::IO, tree, maxdepth = 5; depth = 0, active_levels = Int[],
    charset = TreeCharSet())
    printnode(io, tree)
    println(io)
    c = children(tree)
    if c !== ()
        i = start(c)
        while !done(c,i)
            child, i = next(c,i)
            active = false
            child_active_levels = active_levels
            print_prefix(io, depth, charset, active_levels)
            if done(c,i)
                print(io, charset.terminator)
            else
                print(io, charset.mid)
                child_active_levels = push!(copy(active_levels), depth)
            end
            print(io, charset.dash, ' ')
            print_tree(io, child; depth = depth + 1,
              active_levels = child_active_levels, charset = charset)
        end
    end
end


end # module
