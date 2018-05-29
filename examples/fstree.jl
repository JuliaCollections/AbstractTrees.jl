using AbstractTrees
import AbstractTrees: children, printnode
import Base: start, done, next

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

start(l::DirectoryListing) = start(l.names)
function next(l::DirectoryListing, i)
    (v,i) = next(l.names,i)
    path = joinpath(l.d.path,v)
    (isdir(path) ? Directory(path) : File(path), i)
end
done(l::DirectoryListing, i) = done(l.names, i)

# Pretty printing
printnode(io::IO, d::Directory) = Base.print_with_color(:blue, io, basename(d.path))
printnode(io::IO, f::File) = print(io, basename(f.path))
