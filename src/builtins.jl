# Tree API implementations for builtin types

children(x::AbstractArray) = x

children(x::Tuple) = x

children(x::Expr) = x.args

children(p::Pair) = (p[2],)

children(dict::AbstractDict) = pairs(dict)
