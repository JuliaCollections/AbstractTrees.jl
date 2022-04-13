"""
    ParentLinks

Abstract type of the trait that indicates whether the parents of a node are stored.
"""
abstract type ParentLinks end

"""
    StoredParents <: ParentLinks

Indicates that this node stores parent links explicitly. The implementation
is responsible for defining the parentind function to expose this
information.
"""
struct StoredParents <: ParentLinks; end

"""
    ImplicitParents <: ParentLinks

Indicates that the tree does not store parents.  In these cases parents must be inferred from
the tree structure and cannot be inferred through a single node.
"""
struct ImplicitParents <: ParentLinks; end

"""
    parentlinks(::Type{T})
    parentlinks(tree)

A trait which indicates whether a tree node stores references to its parents (`StoredParents()`) or
if the parents must be inferred from the tree structure (`ImplicitParents()`).

**OPTIONAL**: This should be implemented for a tree if parents of nodes are stored
```julia
AbstractTrees.parentlinks(::Type{<:TreeType}) = AbstractTrees.StoredParents()
```
"""
parentlinks(::Type) = ImplicitParents()
parentlinks(tree) = parentlinks(typeof(tree))

"""
    SiblingLinks

Abstract type of the trait that indicates whether siblings of a node are stored.
"""
abstract type SiblingLinks end

"""
    StoredSiblings <: SiblingLinks

Indicates that this tree node stores sibling links explicitly, or can compute them
quickly (e.g. because the tree has a (small) fixed branching ratio, so the
current index of a node can be determined by quick linear search). The
implementation is responsible for defining the relative_state function
to expose this information.
"""
struct StoredSiblings <: SiblingLinks; end

"""
    ImplicitSiblings <: SiblingLinks

Indicates that tree nodes do not store references to siblings so that they must be inferred
from the tree structure.
"""
struct ImplicitSiblings <: SiblingLinks; end

"""
    StoredSiblingsWithParent <: SiblingLinks

Indicates that the parent of the tree node stores references to its siblings.
"""
struct StoredSiblingsWithParent <: SiblingLinks; end

"""
    siblinglinks(::Type{T})
    siblinglinks(tree)

A trait which indicates whether a tree node stores references to its siblings (`StoredSiblings()`),
the nodes parents store references to its siblings (`StoredSiblingsWithParent()`) or the siblings
must be inferred from the tree structure (`ImplicitSiblings()`).

**OPTIONAL**: This should be implemented for a tree if siblings of nodes are stored
```julia
AbstractTrees.siblinglinks(::Type{<:TreeType}) = AbstractTrees.StoredSiblings()
```
"""
siblinglinks(::Type) = ImplicitSiblings()
siblinglinks(tree) = siblinglinks(typeof(tree))

"""
    TreeKind

Abstract type which indicates the access type of the tree.
"""
abstract type TreeKind end

"""
    RegularTree <: TreeKind

Indicates a tree with no special access properties, that is, `children` returns an (in general non-iterable) collection.
"""
struct RegularTree <: TreeKind; end

"""
    IndexedTree <: TreeKind

Indicates a tree for which `children` returns an indexed collection.
"""
struct IndexedTree <: TreeKind; end

"""
    treekind(::Type{T})
    treekind(tree)

A trait which indicates wither tree nodes has indexable children (`IndexedTree()`), otherwise returns `RegularTree()`.

**OPTIONAL**: This should be implemented for a tree if children are indexable.
```julia
AbstractTrees.treekind(::Type{<:TreeType}) = AbstractTrees.IndexedTree()
```

"""
treekind(tree::Type) = RegularTree()
treekind(tree) = treekind(typeof(tree))

"""
    nodetype(tree)

A trait function, defined on the tree object, specifying the types of the nodes.
The default is `Any`. When applicable, define this trait to make iteration inferrable.

## Example
```
struct IntTree
    num::Int
    children::Vector{IntTree}
end

AbstractTrees.children(itree::IntTree) = itree.children
AbstractTrees.nodetype(::IntTree) = IntTree
```

This suffices to make iteration over, e.g., `Leaves(itree::IntTree)` inferrable.
"""
nodetype(tree) = Any

"""
    idxtype(tree)

A trait function which indicates the type of indices of the tree, defaults to `Int`.
"""
idxtype(tree) = Int
