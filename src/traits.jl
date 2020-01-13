abstract type ParentLinks end

"""
  Indicates that this tree stores parent links explicitly. The implementation
  is responsible for defining the parentind function to expose this
  information.
"""
struct StoredParents <: ParentLinks; end
struct ImplicitParents <: ParentLinks; end

parentlinks(::Type) = ImplicitParents()
parentlinks(tree) = parentlinks(typeof(tree))

abstract type SiblingLinks end

"""
  Indicates that this tree stores sibling links explicitly, or can compute them
  quickly (e.g. because the tree has a (small) fixed branching ratio, so the
  current index of a node can be determined by quick linear search). The
  implementation is responsible for defining the relative_state function
  to expose this information.
"""
struct StoredSiblings <: SiblingLinks; end
struct ImplicitSiblings <: SiblingLinks; end

siblinglinks(::Type) = ImplicitSiblings()
siblinglinks(tree) = siblinglinks(typeof(tree))

struct ImplicitRootState
end

"""
    state = rootstate(tree)

Trees must override with method if the state of the root is not the same as the
tree itself (e.g. IndexedTrees should always override this method).
"""
rootstate(x) = ImplicitRootState()


abstract type TreeKind end
struct RegularTree <: TreeKind; end
struct IndexedTree <: TreeKind; end

treekind(tree::Type) = RegularTree()
treekind(tree) = treekind(typeof(tree))
children(tree, node, ::RegularTree) = children(node)
children(tree, ::ImplicitRootState, ::RegularTree) = children(tree)
children(tree, node, ::IndexedTree) = (tree[y] for y in childindices(tree, node))
children(tree, node) = children(tree, node, treekind(tree))

childindices(tree, node) =
  tree == node ? childindices(tree, rootstate(tree)) :
  error("Must implement childindices(tree, node)")
function childindices()
end

function parentind
end

"""
    nodetype(tree)

A trait function, defined on the tree object, specifying the types of the nodes.
The default is `Any`. When applicable, define this trait to make iteration inferrable.

# Example

```jldoctest
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
idxtype(tree) = Int
