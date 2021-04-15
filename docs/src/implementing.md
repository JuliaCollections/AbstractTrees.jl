# Implementing the AbstractTrees API


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


All that is needed to implement the `AbstractTrees` interface for `MyNode` is to define the
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

7-element Array{Int64,1}:
 3
 4
 2
 5
 7
 6
 1
```


## Type traits

* [`AbstractTrees.nodetype(tree)`](@ref) can be defined to make iteration inferable.
* [`AbstractTrees.ParentLinks`](@ref) can be defined to return [`AbstractTrees.StoredParents()`](@ref) if a tree type stores explicit links to a parent; [`AbstractTrees.SiblingLinks`](@ref), when set to [`AbstractTrees.StoredSiblings()`](@ref), serves the same role for siblings. See their docstrings for more information.


## Printing

[`print_tree`](@ref) calls the [`printnode`](@ref) function to display the representation of each
node in the tree. The default implementation uses the output of `Base.show` (with an appropriate
`IOContext`). You may override this to customize how your tree is printed:

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
