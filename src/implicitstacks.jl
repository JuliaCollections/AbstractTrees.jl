@compat abstract type ImplicitStack end
@compat struct ImplicitIndexStack{S} <: ImplicitStack
    stack::Vector{S}
end
Base.copy(s::ImplicitIndexStack) = typeof(s)(copy(s.stack))
@compat struct ImplicitNodeStack{T, S} <: ImplicitStack
    node_stack::Vector{T}
    idx_stack::ImplicitIndexStack{S}
end
Base.copy(s::ImplicitNodeStack) = typeof(s)(copy(s.node_stack), copy(s.idx_stack))
Base.isempty(s::ImplicitNodeStack) = isempty(s.node_stack)
Base.isempty(s::ImplicitIndexStack) = isempty(s.stack)
@compat struct ImplicitChildStates{T, S}
    tree::T
    stack::S
end
Base.iteratorsize{T<:ImplicitChildStates}(::Type{T}) = Base.SizeUnknown()
children(states::ImplicitChildStates) = children(states.tree, states.stack)
children(stack::ImplicitNodeStack) = children(stack.node_stack[end])

parentstate(tree, state::ImplicitNodeStack) =
    ImplicitNodeStack(state.node_stack[1:end-1], parentstate(tree, state.idx_stack))
parentstate(tree, state::ImplicitIndexStack) = ImplicitIndexStack(state.stack[1:end-1])
childstates(tree, state) = childstates(tree, state, treekind(tree))
childstates(tree, state::ImplicitStack) = ImplicitChildStates(tree, state)
children(tree, state::ImplicitNodeStack) = isempty(state) ?
    children(tree) : children(tree, state.node_stack[end])
children(tree, state::ImplicitIndexStack) = isempty(state) ?
    children(tree) : children(tree, tree[state.stack[end]])

childstates(s::ImplicitChildStates) = isempty(s.stack) ?
  childstates(s.tree, s.tree) : childstates(s.tree,
    isa(s.stack, ImplicitNodeStack) ? s.stack.node_stack[end] : s.stack.stack[end])
nextind(s::ImplicitChildStates, ind) = nextind(childstates(s), ind)
start(s::ImplicitChildStates) = start(childstates(s))
function next(s::ImplicitChildStates, ind)
    ni = next(childstates(s), ind)[2]
    (update_state!(copy(s.stack), childstates(s), ind, treekind(s.tree)), ni)
end
done(s::ImplicitChildStates, ind) = done(childstates(s), ind)

update_state!(ns, cs, idx, _) = update_state!(ns, cs, idx)
update_state!(ns::ImplicitIndexStack, cs, idx) = (push!(ns.stack, idx); ns)
update_state!(ns::ImplicitIndexStack, cs, idx, ::IndexedTree) = (push!(ns.stack, next(cs, idx)[1]); ns)
function update_state!(ns::ImplicitNodeStack, cs, idx)
    push!(ns.node_stack, next(cs, idx)[1])
    update_state!(ns.idx_stack, cs, idx)
    ns
end

joinstate(state::ImplicitNodeStack, new_state::ImplicitNodeStack) =
    ImplicitNodeStack([state.node_stack; new_state.node_stack],
        joinstate(state.idx_stack, new_state.idx_stack))
joinstate(state::ImplicitIndexStack, new_state::ImplicitIndexStack) =
    ImplicitIndexStack([state.stack; new_state.stack])

isroot(tree, state::ImplicitStack) = isempty(state)
