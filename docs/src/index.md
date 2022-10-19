```@meta
CurrentModule = AbstractTrees
```

# AbstractTrees.jl

This package provides an interface for handling
[tree](https://en.wikipedia.org/wiki/Tree_(graph_theory))-like data structures in Julia.

Specifically, a tree consists of a set of nodes (each of which can be represented by any data type)
which are connected in a graph with no cycles.  For example, each object in the nested array `[1,
[2, 3]]` can be represented by a tree in which the object `[1, [2, 3]]` is itself the root of the
tree, `1` and `[2,3]` are its children and `1`, `2` and `3` are the leaves.

Using this package involves implementing the abstract tree interface which, at a minimum, requires
defining the function [`AbstractTrees.children`](@ref) for an object.

See below for a complete guide on how to implement the interface.

## The Abstract Tree Interface

### Functions
All trees *must* define [`children`](@ref).

By default `children` returns an empty tuple and `parent` returns `nothing`, meaning that all
objects which do not define the abstract trees interface can be considered the sole node of a
tree.

```@docs
children
nodevalue(::Any)
parent
nextsibling
prevsibling
childrentype
childtype
childstatetype
```

!!! note

    In general nodes of a tree do not all need to have the same type, but it is much easier to
    achieve type-stability if they do.  To specify that all nodes of a tree must have the same type,
    one should define `Base.eltype(::Type{<:TreeIterator{T}})`, see [Iteration](@ref).

### Traits

#### `ParentLinks`
The default value of `ParentLinks` is `ImplicitParents`.

Types with the `StoredParents` trait *must* define [`parent`](@ref).

```@docs
ParentLinks
ImplicitParents
StoredParents
```

#### `SiblingLinks`
The default value of `SiblingLinks` is `ImplicitSiblings`.

Types with the `StoredSiblings` trait *must* define [`nextsibling`](@ref) and *may* define
[`prevsibling`](@ref).

```@docs
SiblingLinks
ImplicitSiblings
StoredSiblings
```

#### `ChildIndexing`
```@docs
ChildIndexing
NonIndexedChildren
IndexedChildren
```

The default value of `ChildIndexing` is `NonIndexedChildren`.

Types with the `IndexedChildren` trait *must* return an indexable object from `children` (i.e.
`children(node)[idx]` must be valid for positive integers `idx`).

#### `NodeType`
```@docs
NodeType
NodeTypeUnknown
HasNodeType
```

Providing the `HasNodeType` trait will guarantee that all nodes connected to the node must be of the
type returned by [`nodetype`](@ref).

An important use case of this trait is to guarantee the return types of a `TreeIterator`.  Tree
nodes with `NodeTypeUnknown` cannot have type-stable iteration over the entire tree.

For example
```julia
struct ExampleNode
    x::Int
    children::Vector{ExampleNode}
end

AbstractTrees.nodevalue(x::ExampleNode) = x.x
AbstractTrees.children(x::ExampleNode) = x.children

AbstractTrees.NodeType(::Type{<:ExampleNode}) = HasNodeType()
AbstractTrees.nodetype(::Type{<:ExampleNode}) = ExampleNode
```
In this example, iteration over a tree of `ExampleNode`s is type-stable with `eltype`
`ExampleNode`.

Providing the `nodetype(::Type)` method is preferable to defining `nodetype(::ExampleNode)` because
it ensures that `nodetype` can be involved at compile time even if values are not known.


## The Indexed Tree Interface
The abstract tree interface assumes that all information about the descendants of a node is
accessible through the node itself.  The objects which can implement that interface are the nodes of
a tree, not the tree itself.

The interface for trees which do not possess nodes for which tree structure can be inferred from the
nodes alone is different.  This is done by wrapping nodes in the [`IndexNode`](@ref) nodes which
allow nodes to be accessed from a centralized tree object.

```@docs
IndexNode
```

### Functions
All indexed trees *must* implement [`childindices`](@ref).

Indexed trees rely on [`nodevalue(::Any, ::Any)`](@ref) for obtaining the value of a
node given the tree and index.  By default, `nodevalue(tree, idx) = tree[idx]`, trees which do not
store nodes in this way should define `nodevalue`.

Indexed trees can define [`ParentLinks`](@ref) or [`SiblingLinks`](@ref).  The [`IndexNode`](@ref)s
of a tree will inherit these traits from the wrapped tree.

```@docs
childindices
nodevalue(::Any, ::Any)
parentindex
nextsiblingindex
prevsiblingindex
rootindex
```

## The `AbstractNode` Type
It is not required that objects implementing the AbstractTrees.jl interface are of this type, but it
can be used to indicate that an object *must* implement the interface.
```@docs
AbstractNode
```

## Type Stability and Performance
Because of the recursive nature of trees it can be quite challenging to achieve type stability when
traversing it in any way such as iterating over nodes.  Only trees which guarantee that all nodes
are of the same type (with [`HasNodeType`](@ref)) can be type stable.

To make it easier to convert trees with non-uniform node types this package provides the
`StableNode` type.
```@docs
StableNode
```

To achieve the same performance with custom node types be sure to define at least
```julia
AbstractTrees.NodeType(::Type{<:ExampleNode}) = HasNodeType()
AbstractTrees.nodetype(::Type{<:ExampleNode}) = ExampleNode
```

In some circumstances it is also more efficient for nodes to have [`ChildIndexing`](@ref) since this
also guarantees the type of the iteration state of the iterator returned by `children`.

## Additional Functions
```@docs
getdescendant
nodevalues
ischild
isroot
intree
isdescendant
treebreadth
treeheight
descendleft
getroot
```

## Example Implementations
- All objects in base which define the abstract trees interface are defined in
    [`builtins.jl`](https://github.com/JuliaCollections/AbstractTrees.jl/blob/master/src/builtins.jl).
- [`IDTree`](https://github.com/JuliaCollections/AbstractTrees.jl/blob/master/test/examples/idtree.jl)
- [`OneNode`](https://github.com/JuliaCollections/AbstractTrees.jl/blob/master/test/examples/onenode.jl)
- [`OneTree`](https://github.com/JuliaCollections/AbstractTrees.jl/blob/master/test/examples/onetree.jl)
- [`FSNode`](https://github.com/JuliaCollections/AbstractTrees.jl/blob/master/test/examples/fstree.jl)
- [`BinaryNode`](https://github.com/JuliaCollections/AbstractTrees.jl/blob/master/test/examples/binarytree.jl)
