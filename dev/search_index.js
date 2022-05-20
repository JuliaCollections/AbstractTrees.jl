var documenterSearchIndex = {"docs":
[{"location":"iteration/","page":"Iteration","title":"Iteration","text":"CurrentModule = AbstractTrees","category":"page"},{"location":"iteration/#Iteration","page":"Iteration","title":"Iteration","text":"","category":"section"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"AbstractTrees.jl provides algorithms for iterating through the nodes of trees in certain ways.","category":"page"},{"location":"iteration/#Interface","page":"Iteration","title":"Interface","text":"","category":"section"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"Iterators can be constructed for any tree that implements The Abstract Tree Interface with a 1-argument constructor on the root.  For example collect(Leaves(node)) returns a Vector containing the leaves of the tree of which node is the root.","category":"page"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"Trees can define additional methods to simplify the iteration procedure.  To guarantee to the compiler that all nodes connected to a node of type ExampleNode are of the same type","category":"page"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"Base.IteratorEltype(::Type{<:TreeIterator{ExampleNode}}) = Base.HasEltype()\nBase.eltype(::Type{<:TreeIterator{ExampleNode}}) = ExampleNode","category":"page"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"note: Note\nWhile AbstractTrees.jl does its best to infer types appropriately, it is usually not possible to determine the types involved in iteration over a general tree.  For performance critical trees it is crucial to define Base.IteratorEltype and Base.eltype for TreeIterator.","category":"page"},{"location":"iteration/#Iterators","page":"Iteration","title":"Iterators","text":"","category":"section"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"All iterators provided by AbstractTrees.jl are of the TreeIterator abstract type.","category":"page"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"TreeIterator\nPreOrderDFS\nPostOrderDFS\nLeaves\nSiblings\nStatelessBFS","category":"page"},{"location":"iteration/#AbstractTrees.TreeIterator","page":"Iteration","title":"AbstractTrees.TreeIterator","text":"TreeIterator{T}\n\nAn iterator of a tree that implements the AbstractTrees interface.  Every TreeIterator is simply a wrapper of an IteratorState which fully determine the iteration state and implement their own alternative protocol using next.\n\nConstructors\n\nAll TreeIterators have a one argument constructor T(node) which starts iteration from node.\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.PreOrderDFS","page":"Iteration","title":"AbstractTrees.PreOrderDFS","text":"PreOrderDFS{T,F} <: TreeIterator{T}\n\nIterator to visit the nodes of a tree, guaranteeing that parents will be visited before their children.\n\nOptionally takes a filter function that determines whether the iterator should continue iterating over a node's children (if it has any) or should consider that node a leaf.\n\ne.g. for the tree\n\nAny[Any[1,2],Any[3,4]]\n├─ Any[1,2]\n|  ├─ 1\n|  └─ 2\n└─ Any[3,4]\n   ├─ 3\n   └─ 4\n\nwe will get [[[1, 2], [3, 4]], [1, 2], 1, 2, [3, 4], 3, 4].\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.PostOrderDFS","page":"Iteration","title":"AbstractTrees.PostOrderDFS","text":"PostOrderDFS{T} <: TreeIterator{T}\n\nIterator to visit the nodes of a tree, guaranteeing that children will be visited before their parents.\n\ne.g. for the tree\n\nAny[1,Any[2,3]]\n├─ 1\n└─ Any[2,3]\n   ├─ 2\n   └─ 3\n\nwe will get [1, 2, 3, [2, 3], [1, [2, 3]]].\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.Leaves","page":"Iteration","title":"AbstractTrees.Leaves","text":"Leaves{T} <: TreeIterator{T}\n\nIterator to visit the leaves of a tree, e.g. for the tree\n\nAny[1,Any[2,3]]\n├─ 1\n└─ Any[2,3]\n   ├─ 2\n   └─ 3\n\nwe will get [1,2,3].\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.Siblings","page":"Iteration","title":"AbstractTrees.Siblings","text":"Siblings{T} <: TreeIterator{T}\n\nA TreeIterator which visits the siblings of a node after the provided node.\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.StatelessBFS","page":"Iteration","title":"AbstractTrees.StatelessBFS","text":"StatelessBFS{T} <: TreeIterator{T}\n\nIterator to visit the nodes of a tree, all nodes of a level will be visited before their children\n\ne.g. for the tree\n\nAny[1,Any[2,3]]\n├─ 1\n└─ Any[2,3]\n   ├─ 2\n   └─ 3\n\nwe will get [[1, [2,3]], 1, [2, 3], 2, 3].\n\nWARNING: This is O(n^2), only use this if you know you need it, as opposed to a more standard statefull approach.\n\n\n\n\n\n","category":"type"},{"location":"iteration/#Iterator-States","page":"Iteration","title":"Iterator States","text":"","category":"section"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"Any iterator with a state (that is, all except StatelessBFS) are wrappers around objects which by themselves contain all information needed for iteration.  Such a state defines an alternative iteration protocol which can be iterated through by calling next(s).","category":"page"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"IteratorState\nPreOrderState\nPostOrderState\nLeavesState\nSiblingState","category":"page"},{"location":"iteration/#AbstractTrees.IteratorState","page":"Iteration","title":"AbstractTrees.IteratorState","text":"IteratorState{T<:TreeCursor}\n\nThe state of a TreeIterator object.  These are simple wrappers of TreeCursor objects which define a method for next.  TreeIterators are in turn simple wrappers of IteratorStates.\n\nEach IteratorState fully determines the current iteration state and therefore the next state can be obtained with next (nothing is returned after the final state is reached).\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.PreOrderState","page":"Iteration","title":"AbstractTrees.PreOrderState","text":"PreOrderState{T<:TreeCursor} <: IteratorState{T}\n\nThe iteration state of a tree iterator which guarantees that parent nodes will be visited before their children, i.e. which descends a tree from root to leaves.\n\nThis state implements a next method which accepts a filter function as its first argument, allowing tree branches to be skipped.\n\nSee PreOrderDFS.\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.PostOrderState","page":"Iteration","title":"AbstractTrees.PostOrderState","text":"PostOrderState{T<:TreeCursor} <: IteratorState{T}\n\nThe state of a tree iterator which guarantees that parents are visited after their children, i.e. ascends a tree from leaves to root.\n\nSee PostOrderDFS.\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.LeavesState","page":"Iteration","title":"AbstractTrees.LeavesState","text":"LeavesState{T<:TreeCursor} <: IteratorState{T}\n\nA IteratorState of an iterator which visits the leaves of a tree.\n\nSee Leaves.\n\n\n\n\n\n","category":"type"},{"location":"iteration/#AbstractTrees.SiblingState","page":"Iteration","title":"AbstractTrees.SiblingState","text":"SiblingState{T<:TreeCursor} <: IteratorState{T}\n\nA IteratorState of an iterator which visits all of the tree siblings after the current sibling.\n\nSee Siblings.\n\n\n\n\n\n","category":"type"},{"location":"iteration/#IteratorState-Functions","page":"Iteration","title":"IteratorState Functions","text":"","category":"section"},{"location":"iteration/","page":"Iteration","title":"Iteration","text":"instance\ninitial\nnext\nstatetype","category":"page"},{"location":"iteration/#AbstractTrees.instance","page":"Iteration","title":"AbstractTrees.instance","text":"instance(::Type{<:IteratorState}, node; kw...)\n\nCreate an instance of the given IteratorState around node node.  This is mostly just a constructor for IteratorState except that if node is nothing it will return nothing.\n\n\n\n\n\n","category":"function"},{"location":"iteration/#AbstractTrees.initial","page":"Iteration","title":"AbstractTrees.initial","text":"initial(::Type{<:IteratorState}, node)\n\nObtain the initial IteratorState of the provided type for the node node.\n\n\n\n\n\n","category":"function"},{"location":"iteration/#AbstractTrees.next","page":"Iteration","title":"AbstractTrees.next","text":"next(s::IteratorState)\nnext(f, s::IteratorState)\n\nObtain the next IteratorState after the current one.  If s is the final state, this will return nothing.\n\nThis provides an alternative iteration protocol which only uses the states directly as opposed to Base.iterate which takes an iterator object and the current state as separate arguments.\n\n\n\n\n\n","category":"function"},{"location":"iteration/#AbstractTrees.statetype","page":"Iteration","title":"AbstractTrees.statetype","text":"statetype(::Type{<:TreeIterator})\n\nGives the type of IteratorState which is the state of the provided TreeIterator.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = AbstractTrees","category":"page"},{"location":"#AbstractTrees.jl","page":"Home","title":"AbstractTrees.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package provides an interface for handling tree-like data structures in Julia.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Specifically, a tree consists of a set of nodes (each of which can be represented by any data type) which are connected in a graph with no cycles.  For example, each object in the nested array [1, [2, 3]] can be represented by a tree in which the object [1, [2, 3]] is itself the root of the tree, 1 and [2,3] are its children and 1, 2 and 3 are the leaves.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Using this package involves implementing the abstract tree interface which, at a minimum, requires defining the function AbstractTrees.children for an object.","category":"page"},{"location":"","page":"Home","title":"Home","text":"See below for a complete guide on how to implement the interface.","category":"page"},{"location":"#The-Abstract-Tree-Interface","page":"Home","title":"The Abstract Tree Interface","text":"","category":"section"},{"location":"#Functions","page":"Home","title":"Functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"All trees must define children.","category":"page"},{"location":"","page":"Home","title":"Home","text":"By default children returns an empty tuple and parent returns nothing, meaning that all objects which do not define the abstract trees interface can be considered the sole node of a tree.","category":"page"},{"location":"","page":"Home","title":"Home","text":"children\nnodevalue(::Any)\nparent\nnextsibling\nprevsibling\nchildrentype\nchildtype\nchildstatetype\nsiblings","category":"page"},{"location":"#AbstractTrees.children","page":"Home","title":"AbstractTrees.children","text":"children(node)\n\nGet the immediate children of node node.\n\nBy default, every object is a parent node of an empty set of children.  This is to make it simpler to define trees with nodes of different types, for example arrays are trees regardless of their eltype.\n\nREQUIRED: This is required for all tree nodes with non-empty sets of children.  If it is not possible to infer the children from the node alone, this should be defined for a wrapper object which does.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.nodevalue-Tuple{Any}","page":"Home","title":"AbstractTrees.nodevalue","text":"nodevalue(node)\n\nGet the value associated with a node in a tree.  This removes wrappers such as Indexed or TreeCursors.\n\nBy default, this function is the identity.\n\nOPTIONAL: This should be implemented with any tree for which nodes have some \"value\" apart from the node itself. For example, integers cannot themselves be tree nodes, to create a tree in which the \"nodes\" are integers one can do something like\n\nstruct IntNode\n    value::Int\n    children::Vector{IntNode}\nend\n\nAbstractTrees.nodevalue(n::IntNode) = n.value\n\n\n\n\n\n","category":"method"},{"location":"#AbstractTrees.parent","page":"Home","title":"AbstractTrees.parent","text":"parent(node)\n\nGet the immediate parent of a node node.\n\nBy default all objects are considered nodes of a trivial tree with no children and no parents.  That is, the default method is simply parent(node) = nothing.\n\nOPTIONAL: The 1-argument version of this function must be implemented for nodes with the StoredParents trait.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.nextsibling","page":"Home","title":"AbstractTrees.nextsibling","text":"nextsibling(node)\n\nGet the next sibling (child of the same parent) of the tree node node.  The returned node should be the same as the node that would be returned after node when iterating over (children ∘ parent)(node).\n\nOPTIONAL: This function is required for nodes with the StoredSiblings trait.  There is no default definition.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.prevsibling","page":"Home","title":"AbstractTrees.prevsibling","text":"prevsibling(node)\n\nGet the previous sibling (child of the same parent) of the tree node node.  The returned node should be the same as the node that would be returned prior to node when iterating over (children ∘ parent)(node).\n\nOPTIONAL: This function is optional in all cases.  Default AbstractTrees method assume that it is impossible to obtain the previous sibling and all iterators act in the \"forward\" direction.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.childrentype","page":"Home","title":"AbstractTrees.childrentype","text":"childrentype(::Type{T})\nchildrentype(n)\n\nIndicates the type of the children (the collection of children, not individual children) of the tree node n or its type T.  children should return an object of this type.\n\nIf the childrentype can be inferred from the type of the node alone, the type ::Type{T} definition is preferred (the latter will fall back to it).\n\nOPTIONAL: In most cases, childtype is used instead.  If childtype is not defined it will fall back to eltype ∘ childrentype.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.childtype","page":"Home","title":"AbstractTrees.childtype","text":"childtype(::Type{T})\nchildtype(n)\n\nIndicates the type of children of the tree node n or its type T.\n\nIf childtype can be inferred from the type of the node alone, the type ::Type{T} definition is preferred (the latter will fall back to it).\n\nOPTIONAL: It is strongly recommended to define this wherever possible, as without it almost no tree algorithms can be type-stable.  If childrentype is defined and can be known from the node type alone, this function will fall back to eltype(childrentype(T)).  If this gives a correct result it's not necessary to define childtype.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.childstatetype","page":"Home","title":"AbstractTrees.childstatetype","text":"childstatetype(::Type{T})\nchildstatetype(n)\n\nIndicates the type of the iteration state of the tree node n or its type T.  This is used by tree traversal algorithms which must retain this state.  It therefore is necessary to define this to ensure that most tree traversal is type stable.\n\nOPTIONAL: Type inference is used to attempt to\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"note: Note\nIn general nodes of a tree do not all need to have the same type, but it is much easier to achieve type-stability if they do.  To specify that all nodes of a tree must have the same type, one should define Base.eltype(::Type{<:TreeIterator{T}}), see Iteration.","category":"page"},{"location":"#Traits","page":"Home","title":"Traits","text":"","category":"section"},{"location":"#ParentLinks","page":"Home","title":"ParentLinks","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The default value of ParentLinks is ImplicitParents.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Types with the StoredParents trait must define parent.","category":"page"},{"location":"","page":"Home","title":"Home","text":"ParentLinks\nImplicitParents\nStoredParents","category":"page"},{"location":"#AbstractTrees.ParentLinks","page":"Home","title":"AbstractTrees.ParentLinks","text":"ParentLinks(::Type{T})\nParentLinks(tree)\n\nA trait which indicates whether a tree node stores references to its parents (StoredParents()) or if the parents must be inferred from the tree structure (ImplicitParents()).\n\nTrees for which parentlinks returns StoredParents() MUST implement parent.\n\nIf StoredParents(), all nodes in the tree must also have StoredParents(), otherwise use ImplicitParents().\n\nOPTIONAL: This should be implemented for a tree if parents of nodes are stored\n\nAbstractTrees.parentlinks(::Type{<:TreeType}) = AbstractTrees.StoredParents()\nparent(t::TreeType) = get_parent(t)\n\n\n\n\n\n","category":"type"},{"location":"#AbstractTrees.ImplicitParents","page":"Home","title":"AbstractTrees.ImplicitParents","text":"ImplicitParents <: ParentLinks\n\nIndicates that the tree does not store parents.  In these cases parents must be inferred from the tree structure and cannot be inferred through a single node.\n\n\n\n\n\n","category":"type"},{"location":"#AbstractTrees.StoredParents","page":"Home","title":"AbstractTrees.StoredParents","text":"StoredParents <: ParentLinks\n\nIndicates that this node stores parent links explicitly. The implementation is responsible for defining the parentind function to expose this information.\n\nIf a node in a tree has this trait, so must all connected nodes.  If this is not the case, use ImplicitParents instead.\n\nRequired Methods\n\nparent\n\n\n\n\n\n","category":"type"},{"location":"#SiblingLinks","page":"Home","title":"SiblingLinks","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The default value of SiblingLinks is ImplicitSiblings.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Types with the StoredSiblings trait must define nextsibling and may define prevsibling.","category":"page"},{"location":"","page":"Home","title":"Home","text":"SiblingLinks\nImplicitSiblings\nStoredSiblings","category":"page"},{"location":"#AbstractTrees.SiblingLinks","page":"Home","title":"AbstractTrees.SiblingLinks","text":"SiblingLinks(::Type{T})\nSiblingLinks(tree)\n\nA trait which indicates whether a tree node stores references to its siblings (StoredSiblings()) or must be inferred from the tree structure (ImplicitSiblings()).\n\nIf a node has the trait StoredSiblings(), so must all connected nodes in the tree.  Otherwise, use ImplicitSiblings() instead.\n\nOPTIONAL: This should be implemented for a tree if siblings of nodes are stored\n\nAbstractTrees.SiblingLinks(::Type{<:TreeType}) = AbstractTrees.StoredSiblings()\n\n\n\n\n\n","category":"type"},{"location":"#AbstractTrees.ImplicitSiblings","page":"Home","title":"AbstractTrees.ImplicitSiblings","text":"ImplicitSiblings <: SiblingLinks\n\nIndicates that tree nodes do not store references to siblings so that they must be inferred from the tree structure.\n\n\n\n\n\n","category":"type"},{"location":"#AbstractTrees.StoredSiblings","page":"Home","title":"AbstractTrees.StoredSiblings","text":"StoredSiblings <: SiblingLinks\n\nIndicates that this tree node stores sibling links explicitly, or can compute them quickly (e.g. because the tree has a (small) fixed branching ratio, so the current index of a node can be determined by quick linear search).\n\nIf a node has this trait, so must all connected nodes in the tree.  Otherwise, use ImplicitSiblings() instead.\n\nRequired Methods\n\nnextsibling\n\n\n\n\n\n","category":"type"},{"location":"#ChildIndexing","page":"Home","title":"ChildIndexing","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"ChildIndexing\nNonIndexedChildren\nIndexedChildren","category":"page"},{"location":"#AbstractTrees.ChildIndexing","page":"Home","title":"AbstractTrees.ChildIndexing","text":"ChildIndexing(::Type{N})\nChildIndexing(node)\n\nA trait indicating whether the tree node n has children (as returned by children) which can be indexed using 1-based indexing.\n\nIf a node has the IndexedChildren() so must all connected nodes in the tree.  Otherwise, use NonIndexedChildren() instead.\n\nOptions are either NonIndexedChildren (default) or IndexedChildren.\n\n\n\n\n\n","category":"type"},{"location":"#AbstractTrees.NonIndexedChildren","page":"Home","title":"AbstractTrees.NonIndexedChildren","text":"NonIndexedChildren <: ChildIndexing\n\nIndicates that the object returned by children(n) where n is a tree node is not indexable (default).\n\n\n\n\n\n","category":"type"},{"location":"#AbstractTrees.IndexedChildren","page":"Home","title":"AbstractTrees.IndexedChildren","text":"IndexedChildren <: ChildIndexing\n\nIndicates that the object returned by children(n) where n is a tree node is indexable (1-based).\n\nIf a node has this trait so must all connected nodes in the tree.  Otherwise, use NonIndexedChildren() instead.\n\nRequired Methods\n\nA node node with this trait must return an indexable object from children(node).\n\n\n\n\n\n","category":"type"},{"location":"","page":"Home","title":"Home","text":"The default value of ChildIndexing is NonIndexedChildren.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Types with the IndexedChildren trait must return an indexable object from children (i.e. children(node)[idx] must be valid for positive integers idx).","category":"page"},{"location":"#The-Indexed-Tree-Interface","page":"Home","title":"The Indexed Tree Interface","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The abstract tree interface assumes that all information about the descendants of a node is accessible through the node itself.  The objects which can implement that interface are the nodes of a tree, not the tree itself.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The interface for trees which do not possess nodes for which tree structure can be inferred from the nodes alone is different.  This is done by wrapping nodes in the IndexNode nodes which allow nodes to be accessed from a centralized tree object.","category":"page"},{"location":"","page":"Home","title":"Home","text":"IndexNode","category":"page"},{"location":"#AbstractTrees.IndexNode","page":"Home","title":"AbstractTrees.IndexNode","text":"IndexNode{T,I}\n\nThe node of a tree which implements the indexed tree interface.  Such a tree consists of an object tree from which nodes can be obtained with the two-argument method of nodevalue which by default calls getindex.\n\nAn IndexNode implements the tree interface, and can be thought of an adapter from an object that implements the indexed tree interface to one that implements the tree interface.\n\nIndexNode do not store the value associated with the node but can obtain it by calling nodevalue.\n\nConstructors\n\nIndexNode(tree, node_index)\n\nIndexNode(tree) = IndexNode(tree, rootindex(tree))  # one-argument constructor requires `rootindex`\n\nHere tree is an object which stores or can obtain information for the entire tree structure, and node_index is the index of the node for which node_index is being constructed.\n\n\n\n\n\n","category":"type"},{"location":"#Functions-2","page":"Home","title":"Functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"All indexed trees must implement childindices.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Indexed trees rely on nodevalue(::Any, ::Any) for obtaining the value of a node given the tree and index.  By default, nodevalue(tree, idx) = tree[idx], trees which do not store nodes in this way should define nodevalue.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Indexed trees can define ParentLinks or SiblingLinks.  The IndexNodes of a tree will inherit these traits from the wrapped tree.","category":"page"},{"location":"","page":"Home","title":"Home","text":"childindices\nnodevalue(::Any, ::Any)\nparentindex\nnextsiblingindex\nprevsiblingindex\nrootindex","category":"page"},{"location":"#AbstractTrees.childindices","page":"Home","title":"AbstractTrees.childindices","text":"childindices(tree, node_index)\n\nGet the indices of the children of the node of tree tree specified by node_index.\n\nTo be consistent with children, by default this returns an empty tuple.\n\nREQUIRED for indexed trees:  Indexed trees, i.e. trees that do not implement children must implement this function.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.nodevalue-Tuple{Any, Any}","page":"Home","title":"AbstractTrees.nodevalue","text":"nodevalue(tree, node_index)\n\nGet the value of the node specified by node_index from the indexed tree object tree.\n\nBy default, this falls back to tree[node_index].\n\nOPTIONAL: Indexed trees only require this if the fallback to getindex is not sufficient.\n\n\n\n\n\n","category":"method"},{"location":"#AbstractTrees.parentindex","page":"Home","title":"AbstractTrees.parentindex","text":"parentindex(tree, node_index)\n\nGet the index of the parent of the node of tree tree specified by node_index.\n\nNodes that have no parent (i.e. the root node) should return nothing.\n\nOPTIONAL: Indexed trees with the StoredParents trait must implement this.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.nextsiblingindex","page":"Home","title":"AbstractTrees.nextsiblingindex","text":"nextsiblingindex(tree, node_index)\n\nGet the index of the next sibling of the node of tree tree specified by node_index.\n\nNodes which have no next sibling should return nothing.\n\nOPTIONAL: Indexed trees with the StoredSiblings trait must implement this.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.prevsiblingindex","page":"Home","title":"AbstractTrees.prevsiblingindex","text":"prevsiblingindex(tree, node_index)\n\nGet the index of the previous sibling of the node of tree tree specified by node_index.\n\nNodes which have no previous sibling should return nothing.\n\nOPTIONAL: Indexed trees that have StoredSiblings can implement this, but no built-in tree algorithms require it.\n\n\n\n\n\n","category":"function"},{"location":"#AbstractTrees.rootindex","page":"Home","title":"AbstractTrees.rootindex","text":"rootindex(tree)\n\nGet the root index of the indexed tree tree.\n\nOPTIONAL: The single-argument constructor for IndexNode requires this, but it is not required for any built-in tree algorithms.\n\n\n\n\n\n","category":"function"},{"location":"#Example-Implementations","page":"Home","title":"Example Implementations","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"All objects in base which define the abstract trees interface are defined in   builtins.jl.\nIDTree\nOneNode\nOneTree","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"CurrentModule = AbstractTrees","category":"page"},{"location":"faq/#What-are-the-breaking-changes-in-0.4?","page":"FAQ","title":"What are the breaking changes in 0.4?","text":"","category":"section"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Most trees which only define methods for the single-argument version of children should not be affected by breaking changes in 0.4, though authors of packages containing these should review the new trait system to ensure they have added any appropriate traits which can improve performance.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Iterators types do not have breaking changes.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"There are quite a few breaking changes for features of AbstractTrees.jl which were not documented or poorly documented and were therefore unlikely to be used.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"The most significant changes are for indexed trees which now rely on the IndexNode object and a dedicated set of methods.  Authors of packages using indexed trees should review The Indexed Tree Interface.  Roughly speaking, the changes are","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"children(tree, node) rightarrow childindices(tree, node_index)\nIterator(tree) rightarrow Iterator(IndexNode(tree))\nCheck if your tree satisfies the StoredParents or StoredSiblings traits.\nConsider defining childrentype or childtype (can make some algorithms closer   to type-stable).","category":"page"},{"location":"faq/#Why-were-breaking-changes-necessary-for-0.4?","page":"FAQ","title":"Why were breaking changes necessary for 0.4?","text":"","category":"section"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Prior to v0.4 AbstractTrees.jl confused the distinct concepts:","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"A tree node.\nValues associated with the node (what is now obtained by nodevalue).\nThe position of a node in a tree.\nA tree in its entirety.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"This led to inconsistent implementations particularly of indexed tree types even within AbstractTrees.jl itself.  As of 0.4 the package is much more firmly grounded in the concept of a node, alternative methods for defining trees are simply adaptors from objects to nodes, in particular IndexNode.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"A summary of major internal changes from 0.3 to 0.4 is as follows:","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"All indexed tree methods of basic tree functions have been removed.  Indexed trees now have   dedicated methods such as childindices and parentindex.\nNodes can now implement nodevalue which allows for distinction between values associated with   the nodes and the nodes themselves.\nAll tree navigation is now based on \"cursors\".  A cursor provides the necessary information for   moving betweeen adjacent nodes of a tree.  Iterators now specify the movement among cursor   nodes.\nIterators now depend only on iterator states.  This is mostly for internal convenience and does not   change the external API.\ntreemap and treemap! have been replaced with versions that depend on MapNode.","category":"page"},{"location":"faq/#Why-aren't-all-iterators-trees-by-default?","page":"FAQ","title":"Why aren't all iterators trees by default?","text":"","category":"section"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Iteration is very widely implemented for Julia types and there are many types which define iteration but which don't make sense as trees.  Major examples in Base alone include Number and String, Char and Task.  If there are this many examples in Base there are likely to be a lot more in other packages.","category":"page"},{"location":"faq/#Why-does-treemap-return-a-special-node-type?","page":"FAQ","title":"Why does treemap return a special node type?","text":"","category":"section"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"As described above, older versions of this package conflate tree nodes with values attached to them. This makes sense for certain built-in types, particularly arrays, but it imposes constraints on what types of nodes a tree can have.  In particular, it requires all nodes to be container types (so that they can contain their children).  It was previously not possible to have a tree in which, e.g. the integer 1 was anything other than a leaf node.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"The function treemap is special in that it must choose an appropriate output type for an entire tree.  Nodes of this output tree cannot be chosen to be a simple array, since the contents of arrays would be fully-determined by their children.  In other words, a treemap based on arrays can only map leaves.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Introducing a new type becomes necessary to ensure that it can accommodate arbitrary output types.","category":"page"},{"location":"faq/#Why-is-my-code-type-unstable?","page":"FAQ","title":"Why is my code type unstable?","text":"","category":"section"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Guaranteeing type stability when iterating over trees is challenging to say the least.  There are several major obstacles","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"The children of a tree node do not, in general, have the same type as their parent.\nEven if it is easy to infer the type of a node's immediate children, it is usually much harder to   infer the types of the node's more distant descendants.\nNavigating a tree requires inferring not just the types of the children but the types of the   children's iteration states.  To make matters worse, Julia's Base does not include traits   for describing these, and the Base iteration protocol makes very few assumptions about them.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"All of this means that you are unlikely to get type-stable code from AbstractTrees.jl without some effort.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"The simplest way around this is to define the eltype of tree iterators","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Base.IteratorEltype(::Type{<:TreeIterator{ExampleNode}}) = Base.HasEltype()\nBase.eltype(::Type{<:TreeIterator{ExampleNode}}) = ExampleNode","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"which is equivalent to asserting that all nodes of a tree are of the same type.  Performance critical code must ensure that it is possible to construct such a tree, which may not be trivial.","category":"page"},{"location":"faq/","page":"FAQ","title":"FAQ","text":"Note that even after defining Base.eltype it might still be difficult to achieve type-stability due to the aforementioned difficulties with iteration states.  The most reliable around this is to ensure that the object returned by children is indexable and that the node has the IndexedChildren state.  This guarantees that Int can always be used as an iteration state.","category":"page"},{"location":"internals/","page":"Internals","title":"Internals","text":"CurrentModule = AbstractTrees","category":"page"},{"location":"internals/#Cursors","page":"Internals","title":"Cursors","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Tree iteration algorithms rely on TreeCursor objects.  A TreeCursor is a wrapper for a tree node which contains all information needed to navigate to other positions within the tree.  They themselves are nodes of a tree with the StoredParents and StoredSiblings traits.","category":"page"},{"location":"internals/","page":"Internals","title":"Internals","text":"To achieve this, tree cursors must be declared on root nodes.","category":"page"},{"location":"internals/","page":"Internals","title":"Internals","text":"TreeCursor\nTrivialCursor\nImplicitCursor\nIndexedCursor\nSiblingCursor","category":"page"},{"location":"internals/#AbstractTrees.TreeCursor","page":"Internals","title":"AbstractTrees.TreeCursor","text":"TreeCursor{P,N}\n\nAbstract type for tree cursors which when constructed from a node can be used to navigate the entire tree descended from that node.\n\nTree cursors satisfy the abstract tree interface with a few additional guarantees:\n\nTree cursors all have the StoredParents and StoredSiblings traits.\nAll functions acting on a cursor which returns a tree node is guaranteed to return another TreeCursor.   For example, children, parent and nextsiblin all return a TreeCursor of the same type as   the argument.\n\nTree nodes which define children and have the traits StoredParents and StoredSiblings satisfy the TreeCursor interface, but calling TreeCursor(node) on such a node wraps them in a TrivialCursor to maintain a consistent interface.\n\nConstructors\n\nAll TreeCursors possess (at least) the following constructors\n\nT(node)\nT(parent, node)\n\nIn the former case the TreeCursor is constructed for the tree of which node is the root.\n\n\n\n\n\n","category":"type"},{"location":"internals/#AbstractTrees.TrivialCursor","page":"Internals","title":"AbstractTrees.TrivialCursor","text":"TrivialCursor{P,N} <: TreeCursor{P,N}\n\nA TreeCursor which matches the functionality of the underlying node.  Tree nodes wrapped by this cursor themselves have most of the functionality required of a TreeCursor, this type exists entirely for the sake of maintaining a fully consistent interface with other TreeCursor objects.\n\n\n\n\n\n","category":"type"},{"location":"internals/#AbstractTrees.ImplicitCursor","page":"Internals","title":"AbstractTrees.ImplicitCursor","text":"ImplicitCursor{P,N,S} <: TreeCursor{P,N}\n\nA TreeCursor which wraps nodes which cannot efficiently access either their parents or siblings directly. This should be thought of as a \"worst case scenario\" tree cursor.  In particular, ImplicitCursors store the child iteration state of type S and for any of ImplicitCursors method to be type-stable it must be possible to infer the child iteration state type, see childstatetype.\n\n\n\n\n\n","category":"type"},{"location":"internals/#AbstractTrees.IndexedCursor","page":"Internals","title":"AbstractTrees.IndexedCursor","text":"IndexedCursor{P,N} <: TreeCursor{P,N}\n\nA TreeCursor for tree nodes with the IndexedChildren trait but for which parents and siblings are not directly accessible.\n\nThis type is very similar to ImplicitCursor except that it is free to assume that the child iteration state is an integer starting at 1 which drastially simplifies type inference and slightly simplifies the iteration methods.\n\n\n\n\n\n","category":"type"},{"location":"internals/#AbstractTrees.SiblingCursor","page":"Internals","title":"AbstractTrees.SiblingCursor","text":"SiblingCursor{P,N} <: TreeCursor{P,N}\n\nA TreeCursor for trees with the StoredSiblings trait.\n\n\n\n\n\n","category":"type"},{"location":"internals/#Supporting-Types-and-Functions","page":"Internals","title":"Supporting Types and Functions","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"InitialState\nnodevaluetype\nparenttype","category":"page"},{"location":"internals/#AbstractTrees.InitialState","page":"Internals","title":"AbstractTrees.InitialState","text":"InitialState\n\nA type used for some AbstractTrees.jl iterators to indicate that iteration is in its initial state. Typically this is used for wrapper types to indicate that the iterate function has not yet  been called on the wrapped object.\n\n\n\n\n\n","category":"type"},{"location":"internals/#AbstractTrees.nodevaluetype","page":"Internals","title":"AbstractTrees.nodevaluetype","text":"nodevaluetype(csr::TreeCursor)\n\nGet the type of the wrapped node.  This should match the return type of nodevalue.\n\n\n\n\n\n","category":"function"},{"location":"internals/#AbstractTrees.parenttype","page":"Internals","title":"AbstractTrees.parenttype","text":"parenttype(csr::TreeCursor)\n\nThe return type of parent(csr).  For properly constructed TreeCursors this is guaranteed to be another TreeCursor.\n\n\n\n\n\n","category":"function"}]
}
