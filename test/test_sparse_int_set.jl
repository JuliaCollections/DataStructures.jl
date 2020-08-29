using DataStructures, Test
import DataStructures: SparseIntSet

@testset "SparseIntSet" begin
    @testset "Construction, collect" begin
        data_in = (1,5,100)
        s = SparseIntSet(data_in)
        data_out = collect(s)
        @test all(map(d->in(d,data_out), data_in))
        @test length(data_out) == length(data_in)
    end

    @testset "eltype, empty" begin
        @test eltype(SparseIntSet()) == Int
        @test eltype(typeof(SparseIntSet())) == Int
        @test isequal(empty(SparseIntSet([1,2,3])), SparseIntSet())
    end

    @testset "Core Functionality" begin
        s = SparseIntSet([1,2,10,20,200,300,1000,10000,10002])
        @test last(s) == 10002
        @test first(s) == 1
        @test length(s) == 9
        @test pop!(s) == 10002
        @test length(s) == 8
        @test popfirst!(s) == 1
        @test length(s) == 7
        @test !in(1,s)
        @test !in(10002,s)
        @test in(10000,s)
        @test_throws ArgumentError first(SparseIntSet())
        @test_throws ArgumentError last(SparseIntSet())
        t = copy(s)
        s = SparseIntSet()
        push!(s, 1, 2, 100)
        @test 1 in s
        @test !(3 in s)
        @test 2 in s
        @test 100 in s
        @test !(101 in s)
        @test !(1000 in s)
        @test first(s) == 1
        @test last(s) == 100
        @test s == SparseIntSet([1, 2, 100])
        push!(s, 1000)
        @test [i for i in s] == [1, 2, 100, 1000]
        @test pop!(s) == 1000
        @test s == SparseIntSet([1, 2, 100])
        push!(s, 5000)
        push!(s, 2000)
        pop!(s, 5000)
        @test s.reverse[end] === DataStructures.NULL_INT_PAGE
        b = 1:1000
        s = SparseIntSet(b)
        @test collect(s) == collect(b)
        @test length(s) == length(b)
        @test pop!(s, 100) == 100
        @test_throws BoundsError pop!(s, 100)
        @test pop!(s, 100, 1) == 1
        @test pop!(s, 99, 1) == 99
        @test !in(500000, s)
        @test !in(99, s)
    end

    @testset "setdiff / symdiff" begin
        @test setdiff(SparseIntSet([1, 2, 3, 4]), SparseIntSet([2, 4, 5, 6])) == SparseIntSet([1, 3])
    end

    @testset "setdiff!" begin
        s2 = SparseIntSet([1, 2, 3, 4])
        setdiff!(s2, SparseIntSet([2, 4, 5, 6]))

        @test s2 == SparseIntSet([1, 3])
    end

    @testset "issue #7851" begin
        @test_throws DomainError SparseIntSet(-1)
        @test !(-1 in SparseIntSet(1:10))
    end
    @testset "Copy, copy!, empty" begin
        s1 = SparseIntSet([1,2,3])
        s2 = empty(s1)
        push!(s2, 10000)
        @test !in(10000, s1)
        copy!(s2, s1)
        @test !in(10000, s2)
        push!(s2, 10000)
        @test !in(10000, s1)
        s3 = copy(s2)
        push!(s3, 1000)
        @test !in(1000, s2)
        pop!(s3, 1000)
        pop!(s2, 10000)
        @test in(10000, s3)
        pop!(s3, 10000)
        @test s3 == s2 == s1
        @test collect(s3) == collect(s2) == [1,2,3]


    end

    @testset "Push, union" begin
        # Push, union
        s1 = SparseIntSet()
        @test_throws DomainError push!(s1, -1)
        push!(s1, 1, 10, 100, 1000)
        @test collect(s1) == [1, 10, 100, 1000]
        push!(s1, 606)
        @test collect(s1) == [1, 10, 100, 1000, 606]
        s2 = SparseIntSet()
        @test s2 === union!(s2, s1)
        s3 = SparseIntSet([1, 10, 100])
        union!(s3, [1, 606, 1000])
        s4 = union(SparseIntSet([1, 100, 1000]), SparseIntSet([10, 100, 606]))
        @test s1 == s2 == s3 == s4
    end

    @testset "pop!, delete!" begin
        s = SparseIntSet(1:2:10)
        @test pop!(s, 1) == 1
        @test !(1 in s)
        @test_throws BoundsError pop!(s, 1)
        @test_throws ArgumentError pop!(s, -1)
        @test_throws ArgumentError pop!(s, -1, 1)
        @test pop!(s, 1, 0) == 0
        is = copy(s.packed)
        for i in is; pop!(s, i); end
        @test isempty(s)
        push!(s, 1:2:10...)
        @test pop!(s) == 9
        @test pop!(s) == 7
        @test popfirst!(s) == 1
        @test popfirst!(s) == 5
        @test collect(s) == [3]
        empty!(s)
        @test isempty(s)
    end

    @testset "Intersect" begin
        @test isempty(intersect(SparseIntSet()))
        @test isempty(intersect(SparseIntSet(1:10), SparseIntSet()))
        @test isempty(intersect(SparseIntSet(), SparseIntSet(1:10)))

        @test intersect(SparseIntSet([1,2,3])) == SparseIntSet([1,2,3])

        @test intersect(SparseIntSet(1:7), SparseIntSet(3:10)) ==
              intersect(SparseIntSet(3:10), SparseIntSet(1:7)) == SparseIntSet(3:7)

        @test intersect!(SparseIntSet(1:10), SparseIntSet(1:4), 1:5, [1,2,10]) == SparseIntSet(1:2)
    end

    @testset "Setdiff" begin
        s1 = SparseIntSet(1:100)
        setdiff!(s1, SparseIntSet(1:2:100))
        s2 = setdiff(SparseIntSet(1:100), SparseIntSet(1:2:100))
        @test s1 == s2 == SparseIntSet(2:2:100)

        s1 = SparseIntSet(1:10)
        s2 = SparseIntSet([1:2; 6:100])
        @test setdiff(s1, s2) == setdiff(s1, [1:2; 6:100]) == SparseIntSet(3:5)
    end

    @testset "Subsets, equality" begin
        @test SparseIntSet(2:2:10) < SparseIntSet(1:10)
        @test !(SparseIntSet(2:2:10) < SparseIntSet(2:2:10))
        @test SparseIntSet(2:2:10) <= SparseIntSet(2:10)
        @test SparseIntSet(2:2:10) <= SparseIntSet(2:2:10)
    end
    @testset "zip" begin
    	a = SparseIntSet([1,2,3,5, 6, 9, 12, 24])
    	b = SparseIntSet([6, 12, 24, 1000, 2000, 3000])
    	c = SparseIntSet(2:2:100)
    	d = SparseIntSet(6:3:100)
    	e = SparseIntSet((6, 12))
    	s1 = 0
    	it = zip(a, b, c, d, e)
    	for (ia, ib, ic, id, ie) in it
	    	s1 += a.packed[ia] + b.packed[ib] + c.packed[ic] + d.packed[id] + e.packed[ie]
	    end
	    @test s1 == 5*(6+12)
    	s1 = 0
    	it = zip(a, b, c, d, exclude=(e,))
    	for (ia, ib, ic, id) in it
	    	s1 += a.packed[ia] + b.packed[ib] + c.packed[ic] + d.packed[id]
	    end
	    @test s1 == 4*24
	end
        if VERSION >= v"1.1"
            @test zip() isa Iterators.Zip  # issue 621
        end

end
