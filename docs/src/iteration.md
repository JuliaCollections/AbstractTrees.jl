```@meta
CurrentModule = AbstractTrees
```

# Iteration

AbstractTrees.jl provides algorithms for iterating through the nodes of trees in certain ways.

## Interface
Iterators can be constructed for any tree that implements [The Abstract Tree Interface](@ref) with a
1-argument constructor on the root.  For example `collect(Leaves(node))` returns a `Vector`
containing the leaves of the tree of which `node` is the root.

Trees can define additional methods to simplify the iteration procedure.  To guarantee to the
compiler that all nodes connected to a node of type `ExampleNode` are of the same type
```julia
Base.IteratorEltype(::Type{<:TreeIterator{ExampleNode}}) = Base.HasEltype()
Base.eltype(::Type{<:TreeIterator{ExampleNode}}) = ExampleNode
```

!!! note

    While AbstractTrees.jl does its best to infer types appropriately, it is usually not possible
    to determine the types involved in iteration over a general tree.  For performance critical
    trees it is crucial to define `Base.IteratorEltype` and `Base.eltype` for `TreeIterator`.

## Iterators
All iterators provided by AbstractTrees.jl are of the `TreeIterator` abstract type.

```@docs
TreeIterator
PreOrderDFS
PostOrderDFS
Leaves
Siblings
StatelessBFS
treemap
```

### Iterator States
Any iterator with a state (that is, all except `StatelessBFS`) are wrappers around objects which by
themselves contain all information needed for iteration.  Such a state defines an alternative
iteration protocol which can be iterated through by calling `next(s)`.

```@docs
IteratorState
PreOrderState
PostOrderState
LeavesState
SiblingState
```

#### `IteratorState` Functions
```@docs
instance
initial
next
statetype
```
