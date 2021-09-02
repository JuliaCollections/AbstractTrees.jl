# Implementing the AbstractTrees API



## Children

Consider the following custom node type, which stores a single data value along with an explicit
list of child nodes:


```jldoctest mynode; output = false
struct MyNode{T}
    data::T
    children::Vector{MyNode{T}}
end

MyNode(data::T, children=MyNode{T}[]) where T = MyNode{T}(data, children)

# output

MyNode
```


All that is needed to implement the basic `AbstractTrees` interface for `MyNode` is to define the
appropriate method of [`children`](@ref):


```jldoctest mynode; output = false
using AbstractTrees

AbstractTrees.children(node::MyNode) = node.children

# output
```


This is sufficient to enable most of the functionality of this package, such as basic printing and
tree traversal:


```jldoctest mynode
tree = MyNode(1, [
    MyNode(2, [
        MyNode(3),
        MyNode(4),
    ]),
    MyNode(5),
    MyNode(6, [
        MyNode(7),
    ]),
])

[node.data for node in PostOrderDFS(tree)]

# output

7-element Vector{Int64}:
 3
 4
 2
 5
 7
 6
 1
```


### Child collections

The return value of `children()` does not have to be an array, it can be any collection type.
Collection types which support indexing enable additional features of this package (TODO: which?).
In this case the type should also have an appropriate implementation of `keys()` (and thus
`pairs()`).

Be aware that `AbstractDict` instances cannot be used directly as they behave as a collection
of `Pair`s, which is probably not what you want. Instead wrap the dict in
[`AbstractTrees.DictChildren`](@ref), it will behave as a collection of the dict's values only but
still give the same result with regards to indexing and `keys()`.


### Leaf nodes

If your type should always be considered a leaf node (cannot have any children), defining

```julia
AbstractTrees.children(::MyNode) = ()
```

serves to make this property easily inferrable by the compiler, as an instance of `Tuple{}` is
known to be empty by its type alone.


## Optional functions

These functions have default implementations that depend only on the output of `children`, but may
have suboptimal performance that can be improved by adding a custom method for your type.


### children-related functions

If the `children` method for your type involves a non-trivial amount of computation (e.g. if the
returned child objects need to be created with each call instead of being explicitly stored in the
parent as in the example above) providing your own implementation of these functions may
significantly reduce overhead:

* [`ischild`](@ref)


### Subtree-related

The following functions recurse through a node's entire subtree by default, which should be avoided
if possible:

* [`intree`](@ref)
* [`isdescendant`](@ref)
* [`treebreadth`](@ref)
* [`treesize`](@ref)
* [`treeheight`](@ref)


## Type traits

* [`AbstractTrees.nodetype(tree)`](@ref) can be defined to make iteration inferable.
* [`AbstractTrees.ParentLinks`](@ref) can be defined to return [`AbstractTrees.StoredParents()`](@ref) if a tree type stores explicit links to a parent; [`AbstractTrees.SiblingLinks`](@ref), when set to [`AbstractTrees.StoredSiblings()`](@ref), serves the same role for siblings. See their docstrings for more information.


## Printing

[`print_tree`](@ref) calls the [`AbstractTrees.printnode`](@ref) function to display the
representation of each node in the tree. The default implementation uses the output of `Base.show`
(with an appropriate `IOContext`). You may override this to customize how your tree is printed:

```jldoctest mynode
AbstractTrees.printnode(io::IO, node::MyNode) = print(io, "MyNode($(node.data))")

print_tree(tree)

# output

MyNode(1)
├─ MyNode(2)
│  ├─ MyNode(3)
│  └─ MyNode(4)
├─ MyNode(5)
└─ MyNode(6)
   └─ MyNode(7)
```

Typical implementations will print only a single line, but `print_tree` should maintain proper
formatting and indentation with multi-line output.


## Additional Examples

The [examples folder](https://github.com/JuliaCollections/AbstractTrees.jl/tree/master/examples) contains a number of usage examples of varying complexity.
