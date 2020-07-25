# Tree API implementations for builtin types


# Types which are iterable but shouldn't be considered tree-iterable
children(x::Number) = ()
children(x::Char) = ()
children(x::Task) = ()
children(x::AbstractString) = ()


# Expr
children(x::Expr) = x.args


# AbstractDict
printnode(io::IO, kv::Pair{K,V}) where {K,V} = printnode(io,kv[1])
children(kv::Pair{K,V}) where {K,V} = (kv[2],)


# For potentially-large containers, just show the type
printnode(io::IO, ::T) where T <: Union{AbstractArray, AbstractDict} = print(io, T)
