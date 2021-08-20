struct PairTree{KV <: Pair}
    kv::KV
end
#siblinglinks(pt::Type{<:PairTree}) = StoredSiblings()

struct PairTreeChildren{T}
    pairs::T
end
Base.getindex(mp::PairTreeChildren, ind) = PairTree(ind=>mp.pairs[ind])
function Base.iterate(mp::PairTreeChildren, state...)
    r = iterate(mp.pairs, state...)
    r === nothing && return nothing
    PairTree(r[1]), r[2]
end

function printnode(io::IO, pt::PairTree)
    print(io, pt.kv[1], " => ")
    printnode(io, pt.kv[2])
end
for f in (:treekind, :siblinglinks, :parentlinks)
    @eval $f(pt::PairTree) = $f(pt.kv[2])
end
children(pt::PairTree) = PairTreeChildren(pairs(children(pt.kv[2])))
Base.iterate(pt::PairTree, state...) = iterate(pt.kv, state...)
Base.getindex(pt::PairTree, ind) = getindex(pt.kv, ind)

function iterate(parent::PairTreeChildren, node::PairTree)
    parent_v = parent.data.kv[2]
    ni = nextind(parent_v, node.kv[1])
    PairTree(ni=>parent_v)
end
