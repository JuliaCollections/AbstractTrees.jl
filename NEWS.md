# NEWS.md

## Breaking changes in v0.3

- `getindex(::Any, ::ImplicitRootState)` is no longer defined; packages
  that used this method will now throw a `MethodError`. To circumvent this,
  define `Base.getindex(x::MyTreeType, ::AbstractTrees.ImplicitRootState) = x`.
- By default, the iterators in this package now have the
  `Base.IteratorEltype` trait set to `Base.EltypeUnknown()`.
  This generally produces "narrower" (more concretely-typed) arrays when
  used in conjunction with `collect`.
  However, if you define the method `Base.eltype(::Type{<:TreeIterator{MyTreeType}})`,
  you should also set `Base.IteratorEltype(::Type{<:TreeIterator{MyTreeType}}) = Base.HasEltype()`.
