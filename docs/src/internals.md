```@meta
CurrentModule = AbstractTrees
```

# Cursors

Tree iteration algorithms rely on `TreeCursor` objects.  A `TreeCursor` is a wrapper for a tree node
which contains all information needed to navigate to other positions within the tree.  They
themselves are nodes of a tree with the [`StoredParents`](@ref) and [`StoredSiblings`](@ref) traits.

To achieve this, tree cursors must be declared on root nodes.

```@docs
TreeCursor
TrivialCursor
ImplicitCursor
IndexedCursor
SiblingCursor
```

## Supporting Types and Functions

```@docs
InitialState
nodevaluetype
parenttype
```
