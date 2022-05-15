```@meta
CurrentModule = AbstractTrees
```

# API


## Base

```@docs
AbstractTrees.ImplicitParents
AbstractTrees.ImplicitSiblings
AbstractTrees.ParentLinks
AbstractTrees.SiblingLinks
AbstractTrees.StoredParents
AbstractTrees.StoredSiblings
children
intree
ischild
isdescendant
AbstractTrees.nodetype
AbstractTrees.parentlinks
AbstractTrees.siblinglinks
treebreadth
treeheight
treemap
treemap!
treesize
```


## Printing

```@docs
TreeCharSet
print_tree
repr_tree
printnode
```


## Iteration

### Iteration States
```@docs
IteratorState
next
initial
instance
PreOrderState
PostOrderState
LeavesState
SiblingsState
```

```@docs
Leaves
PostOrderDFS
PreOrderDFS
StatelessBFS
TreeIterator
```


## Other

```@docs
AnnotationNode
ShadowTree
Tree
```
