# Tree API implementations for builtin types


# Types which are iterable but shouldn't be considered tree-iterable
children(x::Number) = ()
children(x::Char) = ()
children(x::Task) = ()
children(x::AbstractString) = ()


# Expr
children(x::Expr) = x.args

function printnode(io::IO, x::Expr)
    print(io, "Expr(")
    show(io, x.head)
    print(io, ")")
end


# AbstractDict
children(d::AbstractDict) = DictChildren(d)

"""
    DictChildren(dict)

A `Dict`-like indexable collection of child nodes. `dict` is an `AbstractDict` or any other
collection type which supports `pairs()`.

Behaves as a collection of the dictionary's *values* as opposed to a collection of pairs as the
dictionary itself does, but still supports indexing with keys. The `pairs()` function gives the same
result as the original dict.
"""
struct DictChildren{K, V, D}
    dict::D

    DictChildren(dict) = new{keytype(dict), valtype(dict), typeof(dict)}(dict)
end

Base.eltype(::Type{DictChildren{K, V, D}}) where {K, V, D} = V
Base.keytype(::Type{DictChildren{K, V, D}}) where {K, V, D} = K
Base.valtype(::Type{DictChildren{K, V, D}}) where {K, V, D} = V

Base.length(c::DictChildren) = length(c.dict)
Base.keys(c::DictChildren) = keys(c.dict)
Base.values(c::DictChildren) = values(c.dict)
Base.pairs(c::DictChildren) = pairs(c.dict)
Base.iterate(c::DictChildren, args...) = iterate(values(c.dict), args...)
Base.getindex(c::DictChildren, key) = c.dict[key]


# For potentially-large containers, just show the type
printnode(io::IO, ::T) where T <: Union{AbstractArray, AbstractDict} = print(io, T)

if isdefined(Core.Compiler, :Timings)
    children(t::Core.Compiler.Timings.Timing) = t.children
    printnode(io::IO, t::Core.Compiler.Timings.Timing) = print(io, t.time/10^6, "ms: ", t.mi_info)
    nodetype(t::Core.Compiler.Timings.Timing) = Core.Compiler.Timings.Timing
end
