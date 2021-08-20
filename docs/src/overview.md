# AbstractTrees API Overview

Trees come in many shapes and sizes. For some, the tree structure is explicit,
for some implicit. Some store links to their children and parents. Others don't.
Some have stored or easily computable children, for others (e.g. file system
trees) accessing the list of children can be quite expensive. As such, providing
(efficient) abstractions over these various kinds of data structures is no easy
task. This packages aims to provide easy interfaces that other packages whose
data has treelike structure may plug into, to provide a common vocabulary of
tree operations. It does not itself provide any particular tree structure.
This package is supposed to be easy to integrate. For some trees, no additional
code may be required at all or only for efficiency. For others, the tree
interface should be declarable in a small number of methods.
