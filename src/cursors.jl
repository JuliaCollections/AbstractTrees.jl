"""
    NodeCompletion
"""
struct NodeCompletion{R, T}
    tree::R
    node::T
end

getnode(nc::NodeCompletion) = nc.node
children(nc::NodeCompletion) = nc
function Base.iterate(nc::NodeCompletion)
    cs = children(nc.tree, nc.node)
    r = iterate(cs)
    r === nothing && return nothing
    (node, state) = r
    NodeCompletion(nc.tree, node), (cs, state)
end
function Base.iterate(nc::NodeCompletion, (cs, state))
    r = iterate(cs, state)
    r === nothing && return nothing
    (node, state) = r
    NodeCompletion(nc.tree, node), (cs, state)
end


"""
    LinkedTreeCursor

A TreeCustor is an adaptor that allows parent/sibling navigation over a tree that
does not otherwise explicitly store these relations.
"""
abstract type TreeCursor end
parentlinks(::Type{<:TreeCursor}) = StoredParents()
siblinglinks(::Type{<:TreeCursor}) = StoredSiblings()

struct UnIndex{T} <: TreeCursor
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
    nc = getnode(ui.tc)::NodeCompletion
    nc.tree[nc.node]
end
function parent(ui::UnIndex)
    return UnIndex(parent(ui.tc))
end
children(ui::UnIndex) = ui
function iterate(ui::UnIndex, state...)
    r = iterate(ui.tc, state...)
    r === nothing && return nothing
    (node, state) = r
    UnIndex(node), state
end
isroot(ui::UnIndex) = isroot(ui.tc)

struct SiblingState{ST, SIT}
    siblings::ST
    index::SIT
end

# Not actually executed. Used for inference
function mk_sib_state(tree)
    cs = children(tree)
    (_, state) = iterate(cs)
    SiblingState(cs, state)
end

struct LinkedTreeCursor{SiblingLinks, PT, T, SI <: SiblingState} <: TreeCursor
    parent::Union{Nothing, PT, LinkedTreeCursor{SiblingLinks, PT, T, SI}}
    node::T
    nodepos::Union{SI, Nothing}

    function LinkedTreeCursor(parent::LinkedTreeCursor{SB, PT, S, SI1}, node::T, nodepos) where {SB, PT, T, S, SI1}
        TN = typejoin(T, S)
        SN = typejoin(SI1, typeof(nodepos))
        SN <: SiblingState || (SN = SiblingState)
        if typeof(parent) <: LinkedTreeCursor{SB, PT, TN, SN}
            PTN = PT
        else
            PTN = typejoin(PT, typeof(parent))
            PTN <: LinkedTreeCursor || (PTN = LinkedTreeCursor)
        end
        new{SB, PTN, TN, SN}(parent, node, nodepos)
    end

    function LinkedTreeCursor(parent::Nothing, node::T, nodepos::Union{SiblingState, Nothing}) where {T}
        SN = nodepos === nothing ? Base._return_type(mk_sib_state, Tuple{T}) : typeof(nodepos)
        SN <: SiblingState || (SN = SiblingState)
        new{siblinglinks(node), Union{}, T,  SN}(parent, node, nodepos)
    end
end

function LinkedTreeCursor(tree)
    LinkedTreeCursor(nothing, tree, nothing)
end

isroot(cursor::LinkedTreeCursor) = cursor.parent === nothing
parent(cursor::LinkedTreeCursor) = cursor.parent::LinkedTreeCursor

function nextsibling(cursor::LinkedTreeCursor{StoredSiblings()})
    ns = nextsibling(cursor.node)
    ns === nothing && return ns
    typeof(cursor)(cursor.parent, ns, nothing)
end

function prevsibling(cursor::LinkedTreeCursor{StoredSiblings()})
    ps = prevsibling(cursor.node)
    ps === nothing && return ns
    typeof(cursor)(cursor.parent, ps, nothing)
end

function nextsibling(cursor::LinkedTreeCursor{ImplicitSiblings()})
    siblings = cursor.nodepos.siblings
    pos = cursor.nodepos.index
    r = iterate(siblings, pos)
    r === nothing && return nothing
    ns, nextpos = r
    LinkedTreeCursor(cursor.parent, ns, SiblingState(siblings, nextpos))
end

function prevsibling(cursor::LinkedTreeCursor{ImplicitSiblings()})
    siblings = cursor.nodepos.siblings
    pos = cursor.nodepos.index
    r = iterate(Reverse(siblings), pos)
    r === nothing && return nothing
    ns, prevpos = r
    typeof(cursor)(cursor.parent, ns, SiblingIndex(siblings, prevpos))
end

function Base.iterate(ltc::LinkedTreeCursor)
    cs = children(ltc.node)
    r = iterate(cs)
    r === nothing && return nothing
    ns, state = r
    LinkedTreeCursor(ltc, ns, SiblingState(cs, state)), (cs, state)
end

function Base.iterate(ltc::LinkedTreeCursor, (cs, state))
    r = iterate(cs, state)
    r === nothing && return nothing
    node, state = r
    LinkedTreeCursor(ltc, node, SiblingState(cs, state)), (cs, state)
end

function Base.getindex(ltc::LinkedTreeCursor, idx)
    cs = children(ltc.node)
    LinkedTreeCursor(ltc, cs[idx], SiblingState(cs, idx))
end
Base.lastindex(ltc) = lastindex(ltc.node)

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

function prevsibling(cursor::LinkedTreeCursor{ImplicitSiblings()})
    ps = prevsibling(istc.stack[end])
    ps === nothing && return nothing
    InplaceStackedTreeCursor(update_stack!(istc.stack, ps))
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
        return UnIndex(TreeCursor(NodeCompletion(Indexed(tree), rootindex(tree))))
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
