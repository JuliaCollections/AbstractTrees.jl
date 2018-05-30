using AbstractTrees
import AbstractTrees: children, printnode

struct Directory
    path::String
end

struct File
    path::String
end

children(f::File) = ()

struct DirectoryListing
    d::Directory
    names::Vector{String}
end

children(d::Directory) = DirectoryListing(d,readdir(d.path))

function Base.iterate(l::DirectoryListing, state...)
    (v,i) = iterate(l.names, state...)
    path = joinpath(l.d.path,v)
    (isdir(path) ? Directory(path) : File(path), i)
end

# Pretty printing
printnode(io::IO, d::Directory) = Base.print_with_color(:blue, io, basename(d.path))
printnode(io::IO, f::File) = print(io, basename(f.path))
