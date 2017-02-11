@compat abstract type ImplicitStack end
immutable ImplicitIndexStack{S} <: ImplicitStack
    stack::Vector{S}
end
Base.copy(s::ImplicitIndexStack) = typeof(s)(copy(s.stack))
"""
Keeps a stack of nodes and their corresponding indices. Note that the last node
is not explicitly stored in the node_stack, such that length(node_stack) ==
length(idx_stack)-1 (unless we're at the root in which case both are empty)
"""
immutable ImplicitNodeStack{T, S} <: ImplicitStack
    node_stack::Vector{T}
    idx_stack::ImplicitIndexStack{S}
end
Base.copy(s::ImplicitNodeStack) = typeof(s)(copy(s.node_stack), copy(s.idx_stack))
Base.isempty(s::ImplicitNodeStack) = isempty(s.idx_stack)
Base.isempty(s::ImplicitIndexStack) = isempty(s.stack)
getnode(tree, ns::ImplicitIndexStack) = isempty(ns.stack) ? tree[rootstate(tree)] :
    (@assert isa(treekind(tree), IndexedTree); tree[ns.stack[end]])
function getnode(tree, stack::ImplicitNodeStack)
    isempty(stack.node_stack) ?
    (isempty(stack.idx_stack) ? tree : children(tree)[stack.idx_stack.stack[end]]) :
    children(stack.node_stack[end])[stack.idx_stack.stack[end]]
end
immutable ImplicitChildStates{T, S}
    tree::T
    stack::S
end
Base.iteratorsize{T<:ImplicitChildStates}(::Type{T}) = Base.SizeUnknown()
children(states::ImplicitChildStates) = children(states.tree, states.stack)

parentstate(tree, state::ImplicitNodeStack) =
    ImplicitNodeStack(state.node_stack[1:end-1], parentstate(tree, state.idx_stack))
parentstate(tree, state::ImplicitIndexStack) = ImplicitIndexStack(state.stack[1:end-1])
childstates(tree, state) = childstates(tree, state, treekind(tree))
childstates(tree, state::ImplicitStack) = ImplicitChildStates(tree, state)
children(tree, state::ImplicitNodeStack) = children(tree, getnode(tree, state))
children(tree, state::ImplicitIndexStack) = isempty(state) ?
    children(tree) : children(tree, tree[state.stack[end]])

childstates(s::ImplicitChildStates) = isempty(s.stack) ?
  childstates(s.tree, s.tree) : childstates(s.tree,
    isa(s.stack, ImplicitNodeStack) ? getnode(s.tree, s.stack) : s.stack.stack[end])
nextind(s::ImplicitChildStates, ind) = nextind(childstates(s), ind)
start(s::ImplicitChildStates) = start(childstates(s))
function next(s::ImplicitChildStates, ind)
    ni = next(childstates(s), ind)[2]
    (update_state!(s.tree, copy(s.stack), childstates(s), ind, treekind(s.tree)), ni)
end
done(s::ImplicitChildStates, ind) = done(childstates(s), ind)

update_state!(tree, ns, cs, idx, _) = update_state!(tree, ns, cs, idx)
update_state!(tree, ns::ImplicitIndexStack, cs, idx) = (push!(ns.stack, idx); ns)
update_state!(tree, ns::ImplicitIndexStack, cs, idx, ::IndexedTree) = (push!(ns.stack, next(cs, idx)[1]); ns)
function update_state!(tree, ns::ImplicitNodeStack, cs, idx)
    !isempty(ns) && push!(ns.node_stack, getnode(tree, ns))
    update_state!(tree, ns.idx_stack, cs, idx)
    ns
end

function joinstate(tree, state::ImplicitNodeStack, new_state::ImplicitNodeStack)
    isempty(new_state) && return state
    ImplicitNodeStack([push!(copy(state.node_stack), getnode(tree, state)); new_state.node_stack],
        joinstate(tree, state.idx_stack, new_state.idx_stack))
end
joinstate(tree, state::ImplicitIndexStack, new_state::ImplicitIndexStack) =
    ImplicitIndexStack([state.stack; new_state.stack])
    
isroot(tree, state::ImplicitStack) = isempty(state)
