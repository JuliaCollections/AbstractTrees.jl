"""
This package is intended to provide an abstract interface for working
with tree structures.
Though the package itself is not particularly sophisticated, it defines
the interface that can be used by other packages to talk about trees.
"""
module AbstractTrees

export print_tree, TreeCharSet, TreeIterator, Leaves, PostOrderDFS, Tree,
    AnnotationNode, StatelessBFS, treemap, treemap!, PreOrderDFS,
    ShadowTree, children

import Base: getindex, setindex!, iterate, nextind, print, show,
    eltype, IteratorSize, IteratorEltype, length, push!, pop!
using Base: SizeUnknown, EltypeUnknown
using Markdown


abstract type AbstractShadowTree end


"""
    children(x)

Return the immediate children of node `x`. You should specialize this method
for custom tree structures. It should return an iterable object for which an
appropriate implementation of `Base.pairs` is available.

The default behavior is to assume that if an object is iterable, iterating over
it gives its children. If an object is not iterable, assume it does not have
children.

# Example

```
struct MyNode{T}
    data::T
    children::Vector{MyNode{T}}
end
AbstractTrees.children(node::MyNode) = node.children
```
"""
children(x) = Base.isiterable(typeof(x)) ? x : ()

has_children(x) = children(x) !== ()


include("traits.jl")
include("implicitstacks.jl")
include("printing.jl")
include("indexing.jl")
include("iteration.jl")


## Special cases

# Types which are iterable but shouldn't be considered tree-iterable
children(x::Number) = ()
children(x::Char) = ()
children(x::Task) = ()
children(x::AbstractString) = ()

# Define this here, there isn't really a good canonical package to define this
# elsewhere
children(x::Expr) = x.args

# For AbstractDicts

printnode(io::IO, kv::Pair{K,V}) where {K,V} = printnode(io,kv[1])
children(kv::Pair{K,V}) where {K,V} = (kv[2],)

# For potentially-large containers, just show the type

printnode(io::IO, ::T) where T <: Union{AbstractArray, AbstractDict} = print(io, T)


end # module
