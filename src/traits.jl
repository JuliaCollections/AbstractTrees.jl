@compat abstract type ParentLinks end

"""
  Indicates that this tree stores parent links explicitly. The implementation
  is responsible for defining the parentind function to expose this
  information.
"""
@compat struct StoredParents <: ParentLinks; end
@compat struct ImplicitParents <: ParentLinks; end

parentlinks(::Type) = ImplicitParents()
parentlinks(tree) = parentlinks(typeof(tree))

@compat abstract type SiblingLinks end

"""
  Indicates that this tree stores sibling links explicitly, or can compute them
  quickly (e.g. because the tree has a (small) fixed branching ratio, so the
  current index of a node can be determined by quick linear search). The
  implementation is responsible for defining the relative_state function
  to expose this information.
"""
@compat struct StoredSiblings <: SiblingLinks; end
@compat struct ImplicitSiblings <: SiblingLinks; end

siblinglinks(::Type) = ImplicitSiblings()
siblinglinks(tree) = parentlinks(typeof(tree))


@compat abstract type TreeKind end
@compat struct RegularTree <: TreeKind; end
@compat struct IndexedTree <: TreeKind; end

treekind(tree::Type) = RegularTree()
treekind(tree) = treekind(typeof(tree))
children(tree, node, ::RegularTree) = children(node)
children(tree, node, ::IndexedTree) = (tree[y] for y in childindices(tree, node))
children(tree, node) = children(tree, node, treekind(tree))

function rootstate()
end

childindices(tree, node) =
  tree == node ? childindices(tree, rootstate(tree)) :
  error("Must implement childindices(tree, node)")
function childindices()
end

function parentind
end

nodetype(tree) = Any
idxtype(tree) = Int
