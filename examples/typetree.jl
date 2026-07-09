# DataType
function AbstractTrees.children(t::Type)
    t === Function ? Vector{Type}() : filter!(x -> x !== Any,subtypes(t))
end
AbstractTrees.printnode(io::IO,t::Type) = print(io,t)

print_tree(IO)

println()

print_tree(Real)

println()

# Dict
AbstractTrees.children(d::Dict) = [p for p in d]
AbstractTrees.children(p::Pair) = AbstractTrees.children(p[2])
function AbstractTrees.printnode(io::IO,p::Pair)
    isempty(AbstractTrees.children(p[2])) ? print(io,"$(p[1]): $(p[2])") : print(io,"$(p[1]):")
end

d = Dict(:a => 2,:d => Dict(:b => 4,:c => "Hello"),:e => 5.0)

print_tree(d)