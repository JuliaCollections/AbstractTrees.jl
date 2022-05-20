using Pkg

function testpackage(name::AbstractString; orig::Bool=false)
    Pkg.activate(temp=true)
    orig || Pkg.develop(path=joinpath(@__DIR__,".."))
    Pkg.add(name)
    Pkg.test(name)
end
