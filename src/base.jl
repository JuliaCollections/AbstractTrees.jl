
"""
    nodevalue(node)

Get the value associated with a node in a tree.  This removes wrappers such as [`Indexed`](@ref) or [`TreeCursor`](@ref)s.

By default, this function is the identity.

**OPTIONAL**: This should be implemented with any tree for which nodes have some "value" apart from the node itself.
For example, integers cannot themselves be tree nodes, to create a tree in which the "nodes" are integers one can
do something like
```julia
struct IntNode
    value::Int
    children::Vector{IntNode}
end

AbstractTrees.nodevalue(n::IntNode) = n.value
```
"""
nodevalue(node) = node

"""
    nodevalue(tree, node_index)

Get the value of the node specified by `node_index` from the indexed tree object `tree`.

By default, this falls back to `tree[node_index]`.

**OPTIONAL**: Indexed trees only require this if the fallback to `getindex` is not sufficient.
"""
nodevalue(tree, idx) = tree[idx]

"""
    children(node)

Get the immediate children of node `node`.

By default, every object is a parent node of an empty set of children.  This is to make it simpler to define
trees with nodes of different types, for example arrays are trees regardless of their `eltype`.

**REQUIRED**: This is required for all tree nodes with non-empty sets of children.  If it is not possible to infer
the children from the node alone, this should be defined for a wrapper object which does.
"""
children(node) = ()

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
    ischild(node1, node2; equiv=(===))

Check if `node1` is a child of `node2`.

By default this iterates through `children(node2)`, so performance may be improved by adding a
specialized method for given node type.

Equivalence is established with the `equiv` function.  New methods of this function should include this
argument or else it will fall back to `===`.
"""
ischild(node1, node2; equiv=(≡)) = any(node -> equiv(node, node1), children(node2))

"""
    parent(node)

Get the immediate parent of a node `node`.

By default all objects are considered nodes of a trivial tree with no children and no parents.  That is,
the default method is simply `parent(node) = nothing`.

**OPTIONAL**: The 1-argument version of this function must be implemented for nodes with the [`StoredParents`](@ref)
trait.
"""
parent(node) = nothing

"""
    isroot(x)

Whether `x` is the absolute root of a tree.  More specifically, this returns `true` if `parent(x) ≡ nothing`,
or `parent(root, x) ≡ nothing`.  That is, while any node is the root of some tree, this function only returns
true for nodes which have parents which cannot be obtained with the `AbstractTrees` interface.
"""
isroot(root, x) = isnothing(parent(root, x))
isroot(x) = isnothing(parent(x))

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
isdescendant(node1, node2; equiv=(≡)) = !equiv(node1, node2) && intree(node1, node2; equiv=equiv)


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


"""
    AbstractNode{T}

Abstract type of tree nodes that implement the AbstractTrees.jl interface.

It is *NOT* necessary for tree nodes to inherit from this type to implement the AbstractTrees.jl interface.
Conversely, all `AbstractNode` types are required to satisfy the AbstractTrees.jl interface (i.e. they must
at least define [`children`](@ref)).

Package developers should keep in mind when writing methods that most trees *will not* be of this type.
Therefore, any functions which are intended to work on any tree should not dispatch on `AbstractNode`.

The type parameter `T` is the type of the [`nodevalue`](@ref) of the concrete type descented from `AbstractNode`.
"""
abstract type AbstractNode{T} end

function Base.show(io::IO, node::AbstractNode)
    print(io, typeof(node), "(")
    show(io, nodevalue(node))
    print(io, ", nchildren=", length(children(node)), ")")
end

Base.show(io::IO, ::MIME"text/plain", node::AbstractNode) = print_tree(io, node)


"""
    StableNode{T} <: AbstractNode{T}

A node belonging to a tree in which all nodes are of type `StableNode{T}`.  This type is provided so that
trees with [`NodeTypeUnknown`](@ref) can implement methods to be converted to type-stable trees with indexable
`children` which allow for efficient traversal and iteration.

## Constructors
```julia
StableNode{T}(x::T, ch)
StableNode(x, ch=())
StableNode{T}(𝒻, node)
```

## Arguments
- `x`: the value of the constructed node, returned by [`nodevalue`](@ref).
- `ch`: the children of the node, each must be of type `StableNode`.
- `𝒻`: A function which, when called on the node of a tree returns a value which should be wrapped
    by a `StableNode`.  The return value of `𝒻` must be convertible to `T` (see example).
- `T`: The value type of the `StableNode`s in a tree.
- `node`: A node from a tree which is to be used to construct the `StableNode` tree.

## Examples
```julia
t = [1, [2,3]]

node = StableNode{Union{Int,Nothing}}(t) do n
    n isa Integer ? convert(Int, n) : nothing
end
```
In the above example `node` is a tree with [`HasNodeType`](@ref), nodes of type `StableNode{Union{Int,Nothing}}`.
The nodes in the new tree corresponding to arrays have value `nothing` while other nodes have their
corresponding `Int` value.
"""
struct StableNode{T} <: AbstractNode{T}
    value::T
    children::Vector{StableNode{T}}

    # this ensures proper handling of all cases for iterables ch
    StableNode{T}(x::T, ch) where {T} = new{T}(x, collect(StableNode{T}, ch))
end

nodevalue(n::StableNode) = n.value

children(n::StableNode) = n.children

NodeType(::Type{<:StableNode}) = HasNodeType()
nodetype(::Type{StableNode{T}}) where {T} = StableNode{T}

ChildIndexing(::Type{<:StableNode}) = IndexedChildren()

function StableNode{T}(𝒻, node) where {T}
    StableNode{T}(convert(T, 𝒻(node)), map(n -> StableNode{T}(𝒻, n), children(node)))
end

