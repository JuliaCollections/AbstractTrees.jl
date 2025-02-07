# Tree API implementations for builtin types

children(x::AbstractArray) = x

children(x::Tuple) = x

children(x::Expr) = x.args

children(p::Pair) = (p[2],)

children(dict::AbstractDict) = pairs(dict)


# For potentially-large containers, just show the type
printnode(io::IO, ::T) where T <: Union{AbstractArray, AbstractDict} = print(io, T)