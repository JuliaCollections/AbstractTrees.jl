using AbstractTrees
import AbstractTrees: children, printnode

struct File
    path::String
end

children(f::File) = ()

struct Directory
    path::String
end

function children(d::Directory)
    contents = readdir(d.path)
    children = Vector{Union{Directory,File}}(undef,length(contents))
    for (i,c) in enumerate(contents)
        path = joinpath(d.path,c)
        children[i] = isdir(path) ? Directory(path) : File(path)
    end
    return children
end

printnode(io::IO, d::Directory) = print(io, basename(d.path))
printnode(io::IO, f::File) = print(io, basename(f.path))

dirpath = realpath(joinpath(dirname(pathof(AbstractTrees)),".."))
d = Directory(dirpath)
print_tree(d)
