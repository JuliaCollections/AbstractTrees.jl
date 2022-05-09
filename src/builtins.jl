# Tree API implementations for builtin types

children(x::AbstractArray) = x
ChildIndexing(::AbstractArray) = IndexedChildren()

children(x::Expr) = x.args
ChildIndexing(::Expr) = IndexedChildren()

children(p::Pair) = (p[2],)
ChildIndexing(::Pair) = IndexedChildren()

children(dct::AbstractDict) = pairs(dct)
