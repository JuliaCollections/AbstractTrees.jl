# Tree API implementations for builtin types

children(x::AbstractArray) = x
childindexing(x::AbstractArray) = IndexedChildren()

# Expr
children(x::Expr) = x.args
childindexing(x::Expr) = IndexedChildren()
