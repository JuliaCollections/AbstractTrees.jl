#
# children() and related functions
#

"""
    children(node)

Get the immediate children of `node`.

This is the primary function that needs to be implemented for custom tree types. It should return an
iterable object for which an appropriate implementation of `Base.pairs` is available.

The default behavior is to assume that if an object is iterable, iterating over
it gives its children. Non-iterable types are treated as leaf nodes.
"""
children(node) = Base.isiterable(typeof(node)) ? node : ()


"""
    ischild(node1, node2)

Check if `node1` is a child of `node2`.

By default this iterates through ``children(node2)``, so performance may be improved by adding a
specialized method for given node type.
"""
ischild(node1, node2) = any(node -> node === node1, children(node2))


#
# Subtree-related functions
#

"""
    intree(node, root)

Check if `node` is a member of the tree rooted at `root`.

By default this traverses through the entire tree in search of `node`, and so may be slow if a
more specialized method has not been implemented for the given tree type.

See also: [`isdescendant`](@ref)
"""
intree(node, root) = any(n -> n === node, PreOrderDFS(root))

"""
    isdescendant(node1, node2)

Check if `node1` is a descendant of `node2`. This isequivalent to checking whether `node1` is a
member of the subtree rooted at `node2` (see [`intree`](@ref)) except that a node cannot be a
descendant of itself.

Internally this calls `intree(node1, node2)` and so may be slow if a specialized method of that
function is not available.
"""
isdescendant(node1, node2) = node1 !== node2 && intree(node1, node2)


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
