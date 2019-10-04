using DataStructures, Test
import DataStructures: IntSet

@testset "IntSet" begin
    @testset "Construction, collect" begin
        data_in = (1,5,100)
        s = IntSet(data_in)
        data_out = collect(s)
        @test all(map(d->in(d,data_out), data_in))
        @test length(data_out) == length(data_in)
    end

    @testset "eltype, empty" begin
        @test eltype(IntSet()) == Int
        @test eltype(typeof(IntSet())) == Int
        @test isequal(empty(IntSet([1,2,3])), IntSet())
    end

    @testset "show" begin
        @test sprint(show, IntSet()) == "IntSet([])"
        @test sprint(show, IntSet([1,2,3])) == "IntSet([1, 2, 3])"
        @test occursin("...,", sprint(show, complement(IntSet())))
    end

    @testset "Core Functionality" begin
        s = IntSet([0,1,10,20,200,300,1000,10000,10002])
        @test last(s) == 10002
        @test first(s) == 0
        @test length(s) == 9
        @test pop!(s) == 10002
        @test length(s) == 8
        @test popfirst!(s) == 0
        @test length(s) == 7
        @test !in(0,s)
        @test !in(10002,s)
        @test in(10000,s)
        @test_throws ArgumentError first(IntSet())
        @test_throws ArgumentError last(IntSet())
        t = copy(s)
        sizehint!(t, 20000) #check that hash does not depend on size of internal Array{UInt32, 1}
        @test hash(s) == hash(t)
        @test hash(complement(s)) == hash(complement(t))
    end

    @testset "setdiff / symdiff" begin
        @test setdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) == IntSet([1, 3])
        @test symdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) == IntSet([1, 3, 5, 6])
    end

    @testset "setdiff!" begin
        s2 = IntSet([1, 2, 3, 4])
        setdiff!(s2, IntSet([2, 4, 5, 6]))

        @test s2 == IntSet([1, 3])
    end

    @testset "issue #7851" begin
        @test_throws ArgumentError IntSet(-1)
        @test !(-1 in IntSet(0:10))
    end

    #@testset "issue #8570" begin
    #    # This requires 2^29 bytes of storage, which is too much for a simple test
    #    # s = IntSet(2^32)
    #    @test length(s) == 1
    #    for b in s; b; end
    #end

    @testset "Copy, copy!, empty" begin
        s1 = IntSet([1,2,3])
        s2 = empty(s1)
        copy!(s2, s1)
        s3 = copy(s2)
        @test s3 == s2 == s1
        @test collect(s3) == collect(s2) == [1,2,3]
    end

    @testset "complement! / pop!" begin
        c1 = complement!(IntSet())
        s1 = IntSet([1,2,3])

        pop!(c1, 1)
        pop!(c1, 2)
        pop!(c1, 3)
        c2 = empty(c1)
        copy!(c2, c1)
        c3 = copy(c2)
        c4 = complement(s1)
        @test c1 == c2 == c3 == c4
        @test c4 === sizehint!(c4, 100)
        @test c1 == c4
        @test last(c1) == typemax(Int)-1
        @test last(complement(IntSet())) == typemax(Int)-1
    end

    @testset "Push, union" begin
        # Push, union
        s1 = IntSet()
        @test_throws ArgumentError push!(s1, -1)
        push!(s1, 1, 10, 100, 1000)
        @test collect(s1) == [1, 10, 100, 1000]
        push!(s1, 606)
        @test collect(s1) == [1, 10, 100, 606, 1000]
        s2 = IntSet()
        @test s2 === union!(s2, s1)
        s3 = IntSet([1, 10, 100])
        union!(s3, [1, 606, 1000])
        s4 = union(IntSet([1, 100, 1000]), IntSet([10, 100, 606]))
        @test s1 == s2 == s3 == s4

        c1 = complement(s1)
        @test !(1 in c1)
        push!(c1, 1)
        @test 1 in c1
        push!(c1, 10, 100, 10)
        @test collect(complement(c1)) == [606, 1000]
        c2 = complement(IntSet([606, 1000]))
        @test c2 === union!(c2, c1)
        c3 = union!(complement(IntSet([10, 606, 1000])), complement(IntSet([1, 606, 1000, 2000])))
        @test c3 == union(complement(IntSet([1, 606, 1000, 2000])), complement(IntSet([10, 606, 1000])))
        c4 = union!(complement(IntSet([1, 10, 606, 1000, 1001])), complement(IntSet([606, 1000])))
        @test c4 == union(complement(IntSet([606, 1000])), complement(IntSet([1, 10, 606, 1000, 1001])))
        c5 = union!(complement(IntSet([10, 606, 1000])), IntSet([0, 10, 20, 30]))
        @test c5 == union(IntSet([0, 10, 20, 30]), complement(IntSet([10, 606, 1000])))
        c6 = union!(complement(IntSet([10, 606, 1000])), IntSet([10, 4000, 3]))
        @test c6 == union(IntSet([10, 4000, 3]), complement(IntSet([10, 606, 1000])))
        @test c1 == c2 == c3 == c4 == c5 == c6
    end

    @testset "pop!, delete!" begin
        s = IntSet(1:2:10)
        @test pop!(s, 1) == 1
        @test !(1 in s)
        @test_throws KeyError pop!(s, 1)
        @test_throws ArgumentError pop!(s, -1)
        @test_throws ArgumentError pop!(s, -1, 1)
        @test_throws ArgumentError pop!(()->throw(ErrorException()), s, -1)
        @test pop!(s, 1, 0) == 0
        @test s === delete!(s, 1)
        for i in s; pop!(s, i); end
        @test isempty(s)
        x = 0
        @test 1 == pop!(()->(x+=1), s, 100)
        @test x == 1
        push!(s, 100)
        @test pop!(()->throw(ErrorException()), s, 100) == 100
        push!(s, 1:2:10...)
        @test pop!(s) == 9
        @test pop!(s) == 7
        @test popfirst!(s) == 1
        @test popfirst!(s) == 3
        @test collect(s) == [5]
        empty!(s)
        @test isempty(s)

        c = complement(IntSet())
        @test pop!(c, 1) == 1
        @test !(1 in c)
        @test_throws KeyError pop!(c, 1)
        @test_throws ArgumentError pop!(c, -1)
        @test_throws ArgumentError pop!(c, -1, 1)
        @test_throws ArgumentError pop!(()->throw(ErrorException()), c, -1)
        @test pop!(c, 1, 0) == 0
        @test c === delete!(c, 1)
        @test popfirst!(c) == 0
        @test popfirst!(c) == 2
        @test_throws ArgumentError pop!(c)
        @test collect(complement(c)) == [0,1,2]
        @test empty!(c) == IntSet()
    end

    @testset "Intersect" begin
        @test isempty(intersect(IntSet()))
        @test isempty(intersect(IntSet(1:10), IntSet()))
        @test isempty(intersect(IntSet(), IntSet(1:10)))
        @test isempty(intersect(IntSet(), complement(IntSet())))
        @test isempty(intersect(IntSet(), complement(IntSet(1:10))))
        @test isempty(intersect(complement(IntSet()), IntSet()))
        @test isempty(intersect(complement(IntSet(1:10)), IntSet()))

        @test intersect(IntSet([1,2,3])) == IntSet([1,2,3])
        @test intersect(complement!(IntSet()), IntSet(1)) ==
              intersect(IntSet(1), complement!(IntSet())) == IntSet(1)

        @test intersect(IntSet(0:7), IntSet(3:10)) ==
              intersect(IntSet(3:10), IntSet(0:7)) == IntSet(3:7)
        @test intersect(complement(IntSet([0:2; 11:16])), IntSet(0:7)) ==
              intersect(IntSet(0:7), complement(IntSet([0:2; 11:16]))) == IntSet(3:7)

        @test intersect(complement(IntSet(5:12)), complement(IntSet(7:10))) ==
              intersect(complement(IntSet(7:10)), complement(IntSet(5:12))) == complement(IntSet(5:12))

        @test intersect(IntSet(0:10), IntSet(1:4), 0:5, [1,2,10]) == IntSet(1:2)
    end

    @testset "Setdiff" begin
        s1 = IntSet(1:100)
        setdiff!(s1, IntSet(1:2:100))
        s2 = setdiff(IntSet(1:100), IntSet(1:2:100))
        @test s1 == s2 == IntSet(2:2:100)
        @test collect(s1) == collect(2:2:100)

        s1 = IntSet(1:10)
        s2 = complement(IntSet(3:5))
        @test setdiff(s1, s2) == setdiff(s1, [0:2; 6:100]) == IntSet(3:5)
        @test isempty(setdiff(complement(IntSet()), complement(IntSet())))
        @test setdiff(complement(IntSet()), complement(IntSet(3:5))) == IntSet(3:5)
        @test setdiff(complement(IntSet(1:5)), complement(IntSet(3:10))) == IntSet([6, 7, 8, 9, 10])
        @test setdiff(complement(IntSet(2:2:10)), IntSet(1:5)) == complement(IntSet([1:5; 6:2:10]))
        @test setdiff!(complement(IntSet()), complement(IntSet())) == IntSet()
        @test setdiff!(complement(IntSet(0:2:10)), complement(IntSet(0:10))) == IntSet(1:2:9)
    end

    @testset "Symdiff" begin
        @test symdiff(IntSet([1, 2, 3, 4]), IntSet([2, 4, 5, 6])) ==
              symdiff(IntSet([2, 4, 5, 6]), IntSet([1, 2, 3, 4])) ==
              symdiff(IntSet([1, 2, 3, 4]), [2, 4, 5, 6]) ==
              symdiff(IntSet([2, 4, 5, 6]), [1, 2, 3, 4]) == IntSet([1, 3, 5, 6])
        @test symdiff(complement(IntSet()), IntSet(2:3)) ==
              symdiff(IntSet(2:3), complement(IntSet())) ==
              symdiff(complement(IntSet()), 2:3) ==complement(IntSet(2:3))

        @test symdiff(complement(IntSet(2:7)), IntSet(5:10)) ==
              symdiff(IntSet(5:10), complement(IntSet(2:7))) == complement(IntSet([2:4; 8:10]))
        @test symdiff(complement(IntSet(3:7)), complement(IntSet(5:10))) == IntSet([3:4; 8:10])
    end

    @testset "Subsets, equality" begin
        @test IntSet(2:2:10) < IntSet(1:10)
        @test !(IntSet(2:2:10) < IntSet(2:2:10))
        @test IntSet(2:2:10) <= IntSet(2:10)
        @test IntSet(2:2:10) <= IntSet(2:2:10)
        @test IntSet(1) < complement!(IntSet())
        @test IntSet(1) <= complement!(IntSet())
        @test !(IntSet(1) < complement!(IntSet(1)))
    end

    @testset "Test logic against Set" begin
        p = IntSet([0,1,4,5])
        resize!(p.bits, 6)
        q = IntSet([0,2,4,6])
        resize!(q.bits, 8)
        p′ = complement(p)
        q′ = complement(q)
        function collect10(itr)
            r = eltype(itr)[]
            for i in itr
                i > 10 && break
                push!(r, i)
            end
            r
        end
        a = Set(p)
        b = Set(q)
        a′ = Set(collect10(p′))
        b′ = Set(collect10(q′))
        for f in (union, intersect, setdiff, symdiff)
            @test collect(f(p, p)) == sort(collect(f(a, a)))
            @test collect(f(q, q)) == sort(collect(f(b, b)))
            @test collect(f(p, q)) == sort(collect(f(a, b)))
            @test collect(f(q, p)) == sort(collect(f(b, a)))

            @test collect10(f(p′, p)) == sort(collect(f(a′, a)))
            @test collect10(f(q′, q)) == sort(collect(f(b′, b)))
            @test collect10(f(p′, q)) == sort(collect(f(a′, b)))
            @test collect10(f(q′, p)) == sort(collect(f(b′, a)))

            @test collect10(f(p, p′)) == sort(collect(f(a, a′)))
            @test collect10(f(q, q′)) == sort(collect(f(b, b′)))
            @test collect10(f(p, q′)) == sort(collect(f(a, b′)))
            @test collect10(f(q, p′)) == sort(collect(f(b, a′)))

            @test collect10(f(p′, p′)) == sort(collect(f(a′, a′)))
            @test collect10(f(q′, q′)) == sort(collect(f(b′, b′)))
            @test collect10(f(p′, q′)) == sort(collect(f(a′, b′)))
            @test collect10(f(q′, p′)) == sort(collect(f(b′, a′)))
        end
    end

    @testset "other 1" begin
        s = IntSet()
        push!(s, 0, 2, 100)
        @test 0 in s
        @test !(1 in s)
        @test 2 in s
        @test 100 in s
        @test !(101 in s)
        @test !(1000 in s)
        @test first(s) == 0
        @test last(s) == 100
        @test s == IntSet([0, 2, 100])
        push!(s, 1000)
        @test [i for i in s] == [0, 2, 100, 1000]
        @test pop!(s) == 1000
        @test s == IntSet([0, 2, 100])
        @test hash(s) == hash(IntSet([0, 2, 100]))
    end

    @testset "other 2" begin
        b = 0:1000
        s = IntSet(b)
        @test collect(s) == collect(b)
        @test length(s) == length(b)
        @test pop!(s, 100) == 100
        @test collect(s) == [0:99; 101:1000]
        @test_throws KeyError pop!(s, 100)
        @test pop!(s, 100, 0) == 0
        @test pop!(s, 99, 0) == 99
        @test pop!(()->1, s, 99) == 1
        @test pop!(()->1, s, 98) == 98
    end

    @testset "show" begin
        show(IOBuffer(), IntSet())
        show(IOBuffer(), complement(IntSet()))
    end

end # @testset IntSet
