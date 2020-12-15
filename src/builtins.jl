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
printnode(io::IO, kv::Pair{K,V}) where {K,V} = printnode(io,kv[1])
children(kv::Pair{K,V}) where {K,V} = (kv[2],)


# For potentially-large containers, just show the type
printnode(io::IO, ::T) where T <: Union{AbstractArray, AbstractDict} = print(io, T)

if isdefined(Core.Compiler, :Timings)
	children(t::Core.Compiler.Timings.Timing) = t.children
	printnode(io::IO, t::Core.Compiler.Timings.Timing) = print(io, t.time/10^6, "ms: ", t.mi_info)
	nodetype(t::Core.Compiler.Timings.Timing) = Core.Compiler.Timings.Timing
end
