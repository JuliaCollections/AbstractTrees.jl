using AbstractTrees

@static if Base.VERSION ≥ v"1.5"
    using InteractiveUtils: subtypes, supertype, supertypes
else
    using InteractiveUtils: subtypes, supertype
    function supertypes(T::Type)
        S = supertype(T)
        if S === T 
            (T,) 
        else
          (T, supertypes(S)...)  
        end
    end
end

"""
    TypeTree

The first thing you might think of is using Type{T} as a node directly. However,
this will create many difficulties with components of AbstractTrees.jl that rely
on the type system (in particular `childrentype`). A simple workaround is to 
use a wrapper type.
"""
struct TypeTree
    t::Type
end
function AbstractTrees.children(t::TypeTree)
    t.t === Function ? Vector{TypeTree}() : map(x->TypeTree(x), filter(x -> x !== Any,subtypes(t.t)))
end
AbstractTrees.printnode(io::IO,t::TypeTree) = print(io,t.t)
AbstractTrees.nodevalue(t::TypeTree) = t.t
AbstractTrees.parent(t::TypeTree) = TypeTree(supertype(t.t))
AbstractTrees.ParentLinks(::Type{TypeTree}) = StoredParents()

module JuliaTypesExamples
abstract type AbstractSuperType end
struct DirectDescendant <: AbstractSuperType end
abstract type AbstractFooBar <: AbstractSuperType end
struct Foo <: AbstractFooBar end
struct Bar <: AbstractFooBar end
end
