# Tree API implementations for builtin types

children(x::AbstractArray) = x
ChildIndexing(::AbstractArray) = IndexedChildren()

children(x::Expr) = x.args
ChildIndexing(::Expr) = IndexedChildren()

children(p::Pair) = (p[2],)
ChildIndexing(::Pair) = IndexedChildren()

children(dict::AbstractDict) = pairs(dict)


# For potentially-large containers, just show the type
printnode(io::IO, ::T) where T <: Union{AbstractArray, AbstractDict} = print(io, T)