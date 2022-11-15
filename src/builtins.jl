# Tree API implementations for builtin types

children(x::AbstractArray) = x

children(x::Tuple) = x

children(x::Expr) = x.args

children(p::Pair) = (p[2],)

children(dict::AbstractDict) = pairs(dict)

# ischildrenempty definition for built in type
ischildenempty(x::AbstractArray) =  length(x) == 0 

ischildenempty(x::AbstractDict) =  length(x) == 0 

# Pairs is an AbstractDict  so this is covered under that efintion
# ischildenempty(x::Pairs) =  length(x) == 0 
