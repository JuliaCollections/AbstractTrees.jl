using AbstractTrees
using AbstractTrees: TreeCharSet


# Node type that wraps an integer value `n` and has two children with value `n + 1`.
# Resulting tree has infinite height.
abstract type AbstractNumTree; end
struct Num <: AbstractNumTree
    n::Int
end
Base.show(io::IO, x::AbstractNumTree) = print(io, x.n)
AbstractTrees.children(x::Num) = (Num(x.n+1), Num(x.n+1))


struct SingleChildInfiniteDepth end
AbstractTrees.children(::SingleChildInfiniteDepth) = (SingleChildInfiniteDepth(),)


# Wrapper around a collection which does not define getindex() or keys()
struct Unindexable{C}
    col::C

    Unindexable(col) = new{typeof(col)}(col)
end

Base.eltype(::Type{Unindexable{C}}) where C = eltype(C)
Base.length(u::Unindexable) = length(u.col)
Base.iterate(u::Unindexable, args...) = iterate(u.col, args...)


# Wrapper around a node which wraps children in UnIndexable
struct UnindexableChildren{N}
    node::N
end

AbstractTrees.children(u::UnindexableChildren) = Unindexable(children(u.node))
AbstractTrees.printnode(io::IO, u::UnindexableChildren) = AbstractTrees.printnode(io, u.node)


@testset "Truncation" begin

    # test that `print_tree(headnode, maxdepth)` truncates the output at right depth
    # julia > print_tree(Num(0), 3)
    # 0
    # ├─ 1
    # │  ├─ 2
    # │  │  ├─ 3
    # │  │  └─ 3
    # │  └─ 2
    # │     ├─ 3
    # │     └─ 3
    # └─ 1
    #    ├─ 2
    #    │  ├─ 3
    #    │  └─ 3
    #    └─ 2
    #       ├─ 3
    #       └─ 3
    #

    truncation_str = TreeCharSet().trunc

    for maxdepth in [3,5,8]
        ptxt = repr_tree(Num(0), maxdepth=maxdepth)

        # Check that we see depth #s the expected number of times
        @test length(findall(string(maxdepth-1), ptxt)) == 2^(maxdepth-1)
        @test length(findall(string(maxdepth), ptxt)) == 2^maxdepth
        @test length(findall(string(maxdepth+1), ptxt)) == 0

        # test that `print_tree(headnode)` prints truncation characters under each
        # node at the maximum depth
        lines = split(ptxt, '\n')
        for i in 1:length(lines)
            if occursin(string(maxdepth), lines[i])
                @test endswith(lines[i+1], truncation_str)
            end
        end
    end

    # test correct number of lines printed 1
    ptxt = repr_tree(SingleChildInfiniteDepth())
    numlines = sum([1 for c in split(ptxt, '\n') if ~isempty(strip(c))])
    @test numlines == 7 # 1 (head node) + 5 (default depth) + 1 (truncation char)

    # test correct number of lines printed 2
    ptxt = repr_tree(SingleChildInfiniteDepth(), maxdepth=3)
    numlines = sum([1 for c in split(ptxt, '\n') if ~isempty(strip(c))])
    @test numlines == 5 # 1 (head node) + 3 (depth) + 1 (truncation char)

    # test correct number of lines printed 3
    ptxt = repr_tree(SingleChildInfiniteDepth(), maxdepth=3, indicate_truncation=false)
    numlines = sum([1 for c in split(ptxt, '\n') if ~isempty(strip(c))])
    @test numlines == 4 # 1 (head node) + 3 (depth)
end


@testset "Child keys" begin
    @testset "AbstractVector" begin
        tree = 1:2

        # let's not bother testing the exact string of the type itself, it breaks too easily

        @test endswith(repr_tree(tree), """
                       ├─ 1
                       └─ 2
                       """)

        @test endswith(repr_tree(tree, printkeys=true), """
                       ├─ 1 ⇒ 1
                       └─ 2 ⇒ 2
                       """)
    end

    @testset "Tuple" begin
        tree = (1, 2)

        @test endswith(repr_tree(tree), """
                       ├─ 1
                       └─ 2
                       """)

        @test endswith(repr_tree(tree, printkeys=true), """
                       ├─ 1 ⇒ 1
                       └─ 2 ⇒ 2
                       """)
    end

    @testset "Matrix" begin
        tree = [1 2; 3 4]

        @test endswith(repr_tree(tree), """
        ├─ (1, 1) ⇒ 1
        ├─ (2, 1) ⇒ 3
        ├─ (1, 2) ⇒ 2
        └─ (2, 2) ⇒ 4
        """)

        @test endswith(repr_tree(tree, printkeys=false), """
        ├─ 1
        ├─ 3
        ├─ 2
        └─ 4
        """)
    end

    @testset "No keys" begin
        tree = UnindexableChildren(1:2)  # Has no method for Base.keys()

        @test repr_tree(tree) == repr_tree(tree.node)
        @test repr_tree(tree, printkeys=true) == repr_tree(tree.node)
    end
end

   
@testset "print_tree with non-indexable children" begin
    tree = Num(0)
    @test repr_tree(UnindexableChildren(tree), maxdepth=4) == repr_tree(tree, maxdepth=4)
end
    
    
# Prints node as cool message box
struct BoxNode
    s::String
    children::Vector
end
    
AbstractTrees.children(n::BoxNode) = n.children
function AbstractTrees.printnode(io::IO, n::BoxNode)
    println(io, "┌", "─" ^ textwidth(n.s), "┐")
    println(io, "│", n.s, "│")
    print(io, "└", "─" ^ textwidth(n.s), "┘")
end

@testset "printnode multiline" begin
    tree = ["foo", BoxNode("bar", [1, 2:4, 5]), "baz"]

    @test endswith(repr_tree(tree), """
                   ├─ "foo"
                   ├─ ┌───┐
                   │  │bar│
                   │  └───┘
                   │  ├─ 1
                   │  ├─ 2:4
                   │  │  ├─ 2
                   │  │  ├─ 3
                   │  │  └─ 4
                   │  └─ 5
                   └─ "baz"
                   """)

    # Test printnode override do block syntax
    str_do = repr_tree(tree) do io, s
        if s isa BoxNode
            print(io, s.s)
        else
            AbstractTrees.printnode(io, s)
        end
    end
    @test endswith(str_do, """
                   ├─ "foo"
                   ├─ bar
                   │  ├─ 1
                   │  ├─ 2:4
                   │  │  ├─ 2
                   │  │  ├─ 3
                   │  │  └─ 4
                   │  └─ 5
                   └─ "baz"
                   """)

    # Test printnode and print_child_key override 
    _f(io, s) = s isa BoxNode ? print(io, s.s) : AbstractTrees.printnode(io, s)
    _g(io, k) = AbstractTrees.print_child_key(io, k-1)
    str = repr_tree(_f, _g, tree; printkeys=true) 
    @test endswith(str, """
                   ├─ 0 ⇒ "foo"
                   ├─ 1 ⇒ bar
                   │      ├─ 0 ⇒ 1
                   │      ├─ 1 ⇒ 2:4
                   │      │      ├─ 0 ⇒ 2
                   │      │      ├─ 1 ⇒ 3
                   │      │      └─ 2 ⇒ 4
                   │      └─ 2 ⇒ 5
                   └─ 2 ⇒ "baz"
                   """)
end
