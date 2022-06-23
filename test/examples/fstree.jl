using AbstractTrees

abstract type FSNode end

struct File <: FSNode
    path::String
end

AbstractTrees.children(::File) = ()

struct Directory <: FSNode
    path::String
end

function AbstractTrees.children(d::Directory)
    contents = readdir(d.path)
    children = Vector{Union{Directory,File}}(undef,length(contents))
    for (i,c) in enumerate(contents)
        path = joinpath(d.path,c)
        children[i] = isdir(path) ? Directory(path) : File(path)
    end
    return children
end

# in real life this probably wouldn't be useful, but it's convenient for testing
AbstractTrees.nodevalue(n::FSNode) = n.path

AbstractTrees.printnode(io::IO, d::Directory) = print(io, basename(d.path))
AbstractTrees.printnode(io::IO, f::File) = print(io, basename(f.path))

function mk_tree_test_dir(f, parentdir=tempdir(); prefix="jl_")
    # While Julia 1.0 can parse this, `mktempdir` does not support the `prefix` kw
    mktempdir(parentdir; prefix=prefix) do path
        cd(path) do
            open(io -> write(io, "test1"), "f1"; write=true)
            mkdir("A")
            open(io -> write(io, "test2"), joinpath("A","f2"); write=true)
            mkdir("B")
            f(path)
        end
    end
end
