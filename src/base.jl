
"""
    unwrap(node)

Unwrap a tree node.  This removes wrappers such as [`Indexed`](@ref) or [`TreeCursor`](@ref)s.

By default, this function is the identity.
"""
unwrap(node) = node

"""
    children([root,] node)

Get the immediate children of node `node` (optionally in the context of tree with root `root`).

**REQUIRED**: The 1-argument version of this function is required for all trees.  The 2-argument version is optional
and falls back to `children(node)`.
"""
children(node) = ()
children(root, node) = children(node)

"""
    siblings(node)

Get the siblings (i.e. children of the parent of) the node `node`.  The fall-back method for this only works for
nodes with the trait [`StoredParents`](@ref).

For a general case iterator see [`Siblings`](@ref).

**OPTIONAL**: This function is optional in all cases.
"""
siblings(node) = siblings(ParentLinks(node), node)
siblings(::StoredParents, node) = (children ∘ parent)(node)

"""
    nextsibling(node)

Get the next sibling (child of the same parent) of the tree node `node`.  The returned node should be the same as
the node that would be returned after `node` when iterating over `(children ∘ parent)(node)`.

**OPTIONAL**: This function is required for nodes with the [`StoredSiblings`](@ref) trait.  There is no default
definition.
"""
function nextsibling end

"""
    prevsibling(node)

Get the previous sibling (child of the same parent) of the tree node `node`.  The returned node should be the same
as the node that would be returned prior to `node` when iterating over `(children ∘ parent)(node)`.

**OPTIONAL**: This function is optional in all cases.  Default AbstractTrees method assume that it is impossible to
obtain the previous sibling and all iterators act in the "forward" direction.
"""
function prevsibling end

"""
    ischild(node1, node2; equiv=(≡))

Check if `node1` is a child of `node2`.

By default this iterates through `children(node2)`, so performance may be improved by adding a
specialized method for given node type.

Equivalence is established with the `equiv` function.  New methods of this function should include this
argument or else it will fall back to `≡`.
"""
ischild(node1, node2; equiv=(≡)) = any(node -> equiv(node, node1), children(node2))

"""
    parent([root,] x)

Get the immediate parent of a node `x`

**OPTIONAL**: The 1-argument version of this function must be implemented for nodes with the [`StoredParents`](@ref)
trait.  The 2-argument version is always optional.
"""
parent(root, x) = parent(x)

"""
    isroot(x)

Whether `x` is the absolute root of a tree.  More specifically, this returns `true` if `parent(x) ≡ nothing`,
or `parent(root, x) ≡ nothing`.  That is, while any node is the root of some tree, this function only returns
true for nodes which have parents which cannot be obtained with the `AbstractTrees` interface.
"""
isroot(root, x) = isnothing(parent(root, x))
isroot(x) = (isnothing ∘ parent)(x)

"""
    intree(node, root; equiv=(≡))

Check if `node` is a member of the tree rooted at `root`.

By default this traverses through the entire tree in search of `node`, and so may be slow if a
more specialized method has not been implemented for the given tree type.

Equivalence is established with the `equiv` function.  Note that new methods should also define `equiv` or calls
may fall back to the default method.

See also: [`isdescendant`](@ref)
"""
intree(node, root; equiv=(≡)) = any(n -> equiv(n, node), PreOrderDFS(root))

"""
    isdescendant(node1, node2; equiv=(≡))

Check if `node1` is a descendant of `node2`. This isequivalent to checking whether `node1` is a
member of the subtree rooted at `node2` (see [`intree`](@ref)) except that a node cannot be a
descendant of itself.

Internally this calls `intree(node1, node2)` and so may be slow if a specialized method of that
function is not available.

Equivalence is established with the `equiv` function.  Note that new methods should also define `equiv` or calls
may fall back to the default method.
"""
isdescendant(node1, node2; equiv=(≡)) = equiv(node1, node2) || intree(node1, node2)


"""
    treesize(node)

Get the size of the tree rooted at `node`.

By default this recurses through all nodes in the tree and so may be slow if a more specialized
method has not been implemented for the given type.
"""
treesize(node) = 1 + mapreduce(treesize, +, children(node), init=0)


"""
    treebreadth(node)

Get the number of leaves in the tree rooted at `node`. Leaf nodes have a breadth of one.

By default this recurses through all nodes in the tree and so may be slow if a more specialized
method has not been implemented for the given type.
"""
treebreadth(node) = isempty(children(node)) ? 1 : mapreduce(treebreadth, +, children(node))


"""
    treeheight(node)

Get the maximum depth from `node` to any of its descendants. Leaf nodes have a height of zero.

By default this recurses through all nodes in the tree and so may be slow if a more specialized
method has not been implemented for the given type.
"""
treeheight(node) = isempty(children(node)) ? 0 : 1 + mapreduce(treeheight, max, children(node))

"""
    descendleft(node)

Descend from the node `node` to the first encountered leaf node by recursively calling
[`children`](@ref) and taking the first child.
"""
function descendleft(node)
    ch = children(node)
    isempty(ch) && return node
    descendleft(first(ch))
end

"""
    getroot(node)

Get the root of the tree containing node `node`.  This requires `node` to have the trait [`StoredParents`](@ref).
"""
getroot(node) = getroot(ParentLinks(node), node)
function getroot(::StoredParents, node)
    p = parent(node)
    while true
        isnothing(p) && return node
        node = p
        p = parent(p)
    end
end
