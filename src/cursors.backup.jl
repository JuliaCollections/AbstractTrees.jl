"""
    NodeChildren

A wrapper for a tree node that allows iteration over its children in cases where the children are
not otherwise stored explicitly, i.e. in cases where the children must be obtained from a separate
tree object.

## Constructors
```
NodeChildren(tree, node)
```

## Arguments
- `tree`: The tree which can be used to obtain node children via `children(tree, node)`.
- `node`: The node to wrap.
"""
struct NodeChildren{R, T}
    tree::R
    node::T
end

"""
    getnode(nc::NodeChildren)

Get the node for which `nc` is a wrapper.
"""
getnode(nc::NodeChildren) = nc.node

children(nc::NodeChildren) = nc

function Base.iterate(nc::NodeChildren)
    cs = children(nc.tree, nc.node)
    r = iterate(cs)
    r === nothing && return nothing
    (node, state) = r
    NodeChildren(nc.tree, node), (cs, state)
end
function Base.iterate(nc::NodeChildren, (cs, state))
    r = iterate(cs, state)
    r === nothing && return nothing
    (node, state) = r
    NodeChildren(nc.tree, node), (cs, state)
end

"""
    TreeCursor

An adaptor that allows parent/sibling navigation over a tree that
does not otherwise explicitly store these relations.
"""
abstract type TreeCursor end

parentlinks(::Type{<:TreeCursor}) = StoredParents()
siblinglinks(::Type{<:TreeCursor}) = StoredSiblings()

# all tree cursors are required to be iterators over their children
children(tc::TreeCursor) = tc

#TODO: we have a big problem with determining child iterator properties because we'd have to call
#`children`... I'm wondering if we should go as far as call `children` on construction...

# this is a fallback and may not apply in all cases
Base.IteratorSize(::Type{<:LinkedTreeCursor}) = SizeUnknown()


"""
    UnIndex <: TreeCursor

A `TreeCursor` that allows non-indexed iteration over tree nodes.
"""
struct UnIndex{T<:TreeCursor} <: TreeCursor
    tc::T
end

function nextsibling(ui::UnIndex)
    ns = nextsibling(ui.tc)
    ns === nothing && return nothing
    UnIndex(ns)
end

function prevsibling(ui::UnIndex)
    ps = prevsibling(ui.tc)
    ps === nothing && return nothing
    UnIndex(ps)
end

function getnode(ui::UnIndex)
    nc = getnode(ui.tc)::NodeChildren
    nc.tree[nc.node]
end

function parent(ui::UnIndex)
    return UnIndex(parent(ui.tc))
end

function Base.iterate(ui::UnIndex, state...)
    r = iterate(ui.tc, state...)
    r === nothing && return nothing
    (node, state) = r
    UnIndex(node), state
end

isroot(ui::UnIndex) = isroot(ui.tc)


abstract type LinkedTreeCursor{P,N} <: TreeCursor end


struct LinkedTreeCursorImplicit{P, N, S, SS} <: LinkedTreeCursor{P,N}
    parent::P  # Nothing or LinkedTreeCursorImplicit
    node::N
    siblings::S
    sibling_state::SS

    function LinkedTreeCursorImplicit(p::Union{Nothing,LinkedTreeCursorImplicit},
                                      n, s=siblings(p, n), ss=nothing)
        new{typeof(p),typeof(n),typeof(s),typeof(ss)}(p, n, s, ss)
    end
end

LinkedTreeCursorImplicit(n) = LinkedTreeCursorImplicit(nothing, n, ())


struct LinkedTreeCursorStored{P, N} <: LinkedTreeCursor{P,N}
    parent::P
    node::N

    function LinkedTreeCursorStored(p::Union{Nothing,LinkedTreeCursorStored}, n)
        new{typeof(p),typeof(n)}(p, n)
    end
end

LinkedTreeCursor(n) = LinkedTreeCursor(nothing, n)


getnode(csr::LinkedTreeCursor) = csr.node

parent(csr::LinkedTreeCursor) = csr.parent

isroot(csr::LinkedTreeCursor) = isnothing(parent(csr))

function nextsibling(csr::LinkedTreeCursorStored)
    ns = nextsibling(getnode(csr))
    isnothing(ns) && return nothing
    LinkedTreeCursorStored(parent(csr), ns)
end

function prevsibling(csr::LinkedTreeCursorStored)
    ps = prevsibling(cursor.node)
    isnothing(ps) && return nothing
    LinkedTreeCursorStored(parent(csr), ps)
end

function _iterate(iterf, csr::LinkedTreeCursorStored, s)
    cs = children(getnode(csr))
    r = iterf(cs, s)
    isnothing(r) && return nothing
    (n, s′) = r
    (LinkedTreeCursorStored(csr, n), s′)
end
# to resolve method ambiguity
Base.iterate(csr::LinkedTreeCursorStored) = _iterate(csr)
Base.iterate(csr::LinkedTreeCursorStored, s) = _iterate(csr, s)

function nextsibling(csr::LinkedTreeCursorImplicit)
    r = iterate(csr.siblings, csr.sibling_state)
    isnothing(r) && return nothing
    (ns, s′) = r
    LinkedTreeCursorImplicit(csr, ns, csr.siblings, s′)
end

function _iterate(iterf, csr::LinkedTreeCursorImplicit, s)
    cs = children(getnode(csr))
    r = iterf(cs, s)
    isnothing(r) && return nothing
    (n, s′) = r
    (LinkedTreeCursorImplicit(csr, n, cs, s′), s′)
end
# to resolve method ambiguity
Base.iterate(csr::LinkedTreeCursorImplicit) = _iterate((x,y) -> iterate(x), csr, nothing)
Base.iterate(csr::LinkedTreeCursorImplicit, s) = _iterate((x,y) -> iterate(x, y), csr, s)


#FIX: getindex is supposed to get child somehow


abstract type TreeIterator{T} end

IteratorEltype(::Type{<:TreeIterator}) = EltypeUnknown()

struct InplaceStackedTreeCursor{T} <: TreeCursor
    stack::Vector{T}
end
InplaceStackedTreeCursor(tree) = InplaceStackedTreeCursor([tree])
getnode(istc::InplaceStackedTreeCursor) = istc.stack[end]
isroot(istc::InplaceStackedTreeCursor) = length(istc.stack) == 1
children(istc::InplaceStackedTreeCursor) = istc

Base.isempty(istc::InplaceStackedTreeCursor) = isempty(children(istc.stack[end]))
function Base.iterate(istc::InplaceStackedTreeCursor)
    cs = children(istc.stack[end])
    r = iterate(cs)
    r === nothing && return nothing
    ns, state = r
    if typeof(ns) <: eltype(istc.stack)
        # DANGER: This is the inplace version. Hopefully in the future we have
        # fast immutable arrays that will obviate this.
        push!(istc.stack, ns)
        stack = istc.stack
    else
        JT = typejoin(eltype(istc.stack), typeof(ns))
        stack = convert(Vector{JT}, istc.stack)
        push!(stack, ns)
    end
    InplaceStackedTreeCursor(stack), (cs, state)
end

function update_stack!(stack, ns)
    if typeof(ns) <: eltype(stack)
        # DANGER: See above
    else
        JT = typejoin(eltype(stack), typeof(ns))
        stack = convert(Vector{JT}, stack)
    end
    stack[end] = ns
    stack
end

function Base.iterate(istc::InplaceStackedTreeCursor, (cs, state))
    r = iterate(cs, state)
    if r === nothing
        pop!(istc.stack)
        return nothing
    end
    ns, state = r
    InplaceStackedTreeCursor(update_stack!(istc.stack, ns)), (cs, state)
end

function nextsibling(istc::InplaceStackedTreeCursor)
    ns = nextsibling(istc.stack[end])
    ns === nothing && return nothing
    InplaceStackedTreeCursor(update_stack!(istc.stack, ns))
end

function Base.getindex(istc::InplaceStackedTreeCursor, idx)
    cs = children(istc.stack[end])
    # DANGER: This is the inplace version. Hopefully in the future we have
    # fast immutable arrays that will obviate this
    ns = cs[idx]
    if typeof(ns) <: eltype(istc.stack)
        # DANGER: This is the inplace version. Hopefully in the future we have
        # fast immutable arrays that will obviate this.
        push!(istc.stack, ns)
        stack = istc.stack
    else
        JT = typejoin(eltype(istc.stack), typeof(ns))
        stack = convert(Vector{JT}, istc.stack)
        push!(stack, ns)
    end
    InplaceStackedTreeCursor(stack)
end

function parent(istc::InplaceStackedTreeCursor)
    pop!(istc.stack)
    InplaceStackedTreeCursor(istc.stack)
end

# Decide what kind of cursor to use for this tree. Trees may override this
# function to return a different cursor type.
function TreeCursor(tree)
    if treekind(tree) === IndexedTree()
        return UnIndex(TreeCursor(NodeChildren(Indexed(tree), rootindex(tree))))
    end
    pl = parentlinks(tree)
    sl = siblinglinks(tree)
    if pl === StoredParents() && sl === StoredSiblings()
        # If both parents and siblings are stored, there is no need for a cursor,
        # the tree itself supports everything we need.
        return tree
    end
    # Ok, we need some kind of cursor. If the siblings are stored, we will
    # consider using a stack based cursor, otherwise we will fall back to the
    # pointer tree one.
    if sl === StoredSiblings()
        # TODO: Some kind of consideration of mutability/non-mutability here?
        return InplaceStackedTreeCursor(tree)
    end
    return LinkedTreeCursor(tree)
end
TreeCursor(tc::TreeCursor) = tc
