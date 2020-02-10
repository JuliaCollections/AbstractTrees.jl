# Wrappers which allow for tree-like indexing into objects


struct Tree
    x::Any
end
Tree(x::Tree) = x
Tree(x::AbstractShadowTree) = x
show(io::IO, tree::Tree) = print_tree(io, tree.x)

mutable struct AnnotationNode{T}
    val::T
    children::Vector{AnnotationNode{T}}
end

children(x::AnnotationNode) = x.children
printnode(io::IO, x::AnnotationNode) = print(io, x.val)

struct ShadowTree <: AbstractShadowTree
    tree::Tree
    shadow::Tree
    ShadowTree(x::Tree,y::Tree) = new(x,y)
    ShadowTree(x,y) = ShadowTree(Tree(x),Tree(y))
end
first_tree(x::ShadowTree) = x.tree
second_tree(x::ShadowTree) = x.shadow

function zip_min(c1, c2)
    n1, n2 = length(c1), length(c2)
    if n1 < n2
        c2 = Iterators.take(c2,n1)
    elseif n2 < n1
        c1 = Iterators.take(c1,n2)
    end
    zip(c1, c2)
end

make_zip(x::AbstractShadowTree) = zip_min(children(x.tree.x), children(x.shadow.x))

function children(x::AbstractShadowTree)
    map(res->typeof(x)(res[1], res[2]),make_zip(x))
end

iterate(x::AbstractShadowTree, state...) = iterate(make_zip(x), state...)

function make_annotations(cb, tree, parent, s)
    s = cb(tree, parent, s)
    AnnotationNode{Any}(s, AnnotationNode{Any}[make_annotations(cb, child, tree, s) for child in children(tree)])
end

function getindex(tree::Tree, indices)
    node = tree.x
    for idx in indices
        node = children(node)[idx]
    end
    node
end
getindex(tree::Tree, indices::T) where {T<:ImplicitNodeStack} =
    getindex(tree, indices.idx_stack.stack)


function getindexhighest(tree::Tree, indices)
    node = tree.x
    for (i,idx) in enumerate(indices)
        cs = children(node)
        if idx > length(cs)
            return (indices[1:i-1],node)
        end
        node = children(node)[idx]
    end
    (indices, node)
end

function setindex!(tree::Tree, val, indices)
    setindex!(children(getindex(tree,indices[1:end-1])),val,indices[end])
end
setindex!(tree::Tree, val, indices::T) where {T<:ImplicitNodeStack} =
    setindex!(tree, val, indices.idx_stack.stack)

function getindex(tree::AbstractShadowTree, indices)
    typeof(tree)(Tree(first_tree(tree))[indices],Tree(second_tree(tree))[indices])
end

function setindex!(tree::AbstractShadowTree, val, indices)
    setindex!(Tree(first_tree(tree)), first_tree(val), indices)
    setindex!(Tree(second_tree(tree)), second_tree(val), indices)
end

function setindex!(tree::AbstractShadowTree, val::Tuple, indices)
    setindex!(Tree(first_tree(tree)), val[1], indices)
    setindex!(Tree(second_tree(tree)), val[2], indices)
end
