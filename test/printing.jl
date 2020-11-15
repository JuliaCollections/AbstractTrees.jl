# Test print_tree()


struct Num{I} end
Num(I::Int) = Num{I}()
Base.show(io::IO, ::Num{I}) where {I} = print(io, I)
AbstractTrees.children(x::Num{I}) where {I} = (Num(I+1), Num(I+1))

struct SingleChildInfiniteDepth end
AbstractTrees.children(::SingleChildInfiniteDepth) = (SingleChildInfiniteDepth(),)


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

    for maxdepth in [3,5,8]
        ptxt = repr_tree(Num(0), maxdepth=maxdepth)

        n1  = sum([1 for c in ptxt if c=="$(maxdepth-1)"[1]])
        n2  = sum([1 for c in ptxt if c=="$maxdepth"[1]])
        n3  = sum([1 for c in ptxt if c=="$(maxdepth+1)"[1]])

        @test n1==2^(maxdepth-1)
        @test n2==2^maxdepth
        @test n3==0
    end

    # test that `print_tree(headnode)` prints truncation characters under each
    # node at the default maxdepth level = 5
    truncation_char = AbstractTrees.TreeCharSet().trunc
    ptxt = repr_tree(Num(0))

    n1  = sum([1 for c in ptxt if c=='5'])
    n2  = sum([1 for c in ptxt if c=='6'])
    n3  = sum([1 for c in ptxt if c==truncation_char])
    @test n1==2^5
    @test n2==0
    @test n3==2^5

    lines = split(ptxt, '\n')
    for i in 1:length(lines)
        if ~isempty(lines[i]) && lines[i][end] == '5'
            @test lines[i+1][end] == truncation_char
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


@testset "print_tree maxdepth as positional argument" begin
    tree = Num(0)

    @test_deprecated print_tree(devnull, tree, 3)
    @test_deprecated print_tree(AbstractTrees.printnode, devnull, tree, 3)

    buf = IOBuffer()

    for maxdepth in [3, 5, 8]
        print_tree(buf, tree, maxdepth)
        str = String(take!(buf))
        truncate(buf, 0)

        @test str == repr_tree(tree, maxdepth=maxdepth)
    end
end