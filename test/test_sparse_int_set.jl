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
        copy!(s2, s1)
        s3 = copy(s2)
        @test s3 == s2 == s1
        @test collect(s3) == collect(s2) == [1,2,3]
    end

    @testset "complement! / pop!" begin
        s1 = SparseIntSet([1,2,3])
        c1 = complement!(SparseIntSet([1,2,3]))
        
        c2 = empty(c1)
        copy!(c2, c1)
        c3 = copy(c2)
        c4 = complement(s1)
        @test c1 == c2 == c3 == c4
        @test last(c1) == DataStructures.INT_PER_PAGE
        @test last(complement(SparseIntSet([1,2,3]))) == DataStructures.INT_PER_PAGE
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

        c1 = complement(s1)
        @test !(1 in c1)
        push!(c1, 1)
        @test 1 in c1
        push!(c1, 10, 100, 10)
        @test collect(complement(c1)) == [606, 1000]
        c2 = complement(SparseIntSet([606, 1000, 2000]))
        @test c2 === union!(c2, c1)
        c3 = union!(complement(SparseIntSet([10, 606, 1000])), complement(SparseIntSet([2, 606, 1000, 2000])))
        @test c3 == union(complement(SparseIntSet([2, 606, 1000, 2000])), complement(SparseIntSet([10, 606, 1000])))
        @test c2 == c3
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

        c = complement(SparseIntSet([1]))
        push!(c, 1)
        @test pop!(c, 1) == 1
        @test !(1 in c)
        @test_throws BoundsError pop!(c, 1)
        @test_throws ArgumentError pop!(c, -1)
        @test_throws ArgumentError pop!(c, -1, 1)
        # @test_throws ArgumentError pop!(()->throw(ErrorException()), c, -1)
        @test pop!(c, 1, 0) == 0
        @test popfirst!(c) == 2
        @test popfirst!(c) == DataStructures.INT_PER_PAGE
        @test empty!(c) == SparseIntSet()
    end

    @testset "Intersect" begin
        @test isempty(intersect(SparseIntSet()))
        @test isempty(intersect(SparseIntSet(1:10), SparseIntSet()))
        @test isempty(intersect(SparseIntSet(), SparseIntSet(1:10)))
        @test isempty(intersect(SparseIntSet(), complement(SparseIntSet())))
        @test isempty(intersect(SparseIntSet(), complement(SparseIntSet(1:10))))
        @test isempty(intersect(complement(SparseIntSet()), SparseIntSet()))
        @test isempty(intersect(complement(SparseIntSet(1:10)), SparseIntSet()))

        @test intersect(SparseIntSet([1,2,3])) == SparseIntSet([1,2,3])
        @test intersect(complement!(SparseIntSet(1)), SparseIntSet(2)) ==
              intersect(SparseIntSet(2), complement!(SparseIntSet(1))) == SparseIntSet(2)

        @test intersect(SparseIntSet(1:7), SparseIntSet(3:10)) ==
              intersect(SparseIntSet(3:10), SparseIntSet(1:7)) == SparseIntSet(3:7)
        @test intersect(complement(SparseIntSet([1:2; 11:16])), SparseIntSet(1:7)) ==
              intersect(SparseIntSet(1:7), complement(SparseIntSet([1:2; 11:16]))) == SparseIntSet(3:7)

        @test intersect(complement(SparseIntSet(5:12)), complement(SparseIntSet(7:10))) ==
              intersect(complement(SparseIntSet(7:10)), complement(SparseIntSet(5:12))) == complement(SparseIntSet(5:12))

        @test intersect!(SparseIntSet(1:10), SparseIntSet(1:4), 1:5, [1,2,10]) == SparseIntSet(1:2)
    end

    @testset "Setdiff" begin
        s1 = SparseIntSet(1:100)
        setdiff!(s1, SparseIntSet(1:2:100))
        s2 = setdiff(SparseIntSet(1:100), SparseIntSet(1:2:100))
        @test s1 == s2 == SparseIntSet(2:2:100)

        s1 = SparseIntSet(1:10)
        s2 = complement(SparseIntSet(3:5))
        @test setdiff(s1, s2) == setdiff(s1, [1:2; 6:100]) == SparseIntSet(3:5)
        @test isempty(setdiff(complement(SparseIntSet()), complement(SparseIntSet())))
        @test setdiff(complement(SparseIntSet(4)), complement(SparseIntSet(3:5))) == SparseIntSet((3,5))
        @test setdiff(complement(SparseIntSet(1:5)), complement(SparseIntSet(3:10))) == SparseIntSet([6, 7, 8, 9, 10])
        @test setdiff(complement(SparseIntSet(2:2:10)), SparseIntSet(1:5)) == complement(SparseIntSet([1:5; 6:2:10]))
        @test setdiff!(complement(SparseIntSet(5)), complement(SparseIntSet(5))) == SparseIntSet()
        @test setdiff!(complement(SparseIntSet(1:2:10)), complement(SparseIntSet(1:10))) == SparseIntSet(2:2:10)
    end

    @testset "Subsets, equality" begin
        @test SparseIntSet(2:2:10) < SparseIntSet(1:10)
        @test !(SparseIntSet(2:2:10) < SparseIntSet(2:2:10))
        @test SparseIntSet(2:2:10) <= SparseIntSet(2:10)
        @test SparseIntSet(2:2:10) <= SparseIntSet(2:2:10)
        @test SparseIntSet(1) < complement!(SparseIntSet([5]))
        @test SparseIntSet(1) <= complement!(SparseIntSet([20]))
        @test !(SparseIntSet(1) < complement!(SparseIntSet(1)))
    end

    @testset "other 1" begin
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

    end

    @testset "other 2" begin
        b = 1:1000
        s = SparseIntSet(b)
        @test collect(s) == collect(b)
        @test length(s) == length(b)
        @test pop!(s, 100) == 100
        @test_throws BoundsError pop!(s, 100)
        @test pop!(s, 100, 1) == 1
        @test pop!(s, 99, 1) == 99
    end

    @testset "zip" begin
    	a = SparseIntSet([1,2,3,5, 6, 9, 12, 24])
    	b = SparseIntSet([6, 12, 24, 1000, 2000, 3000])
    	c = SparseIntSet(2:2:100)
    	d = SparseIntSet(6:3:100)
    	e = SparseIntSet((6, 12))
    	s1 = 0
    	s2 = 0
    	it = zip(a, b, c, d, e)
    	for (ia, ib, ic, id, ie) in it
	    	s1 += a.packed[ia] + b.packed[ib] + c.packed[ic] + d.packed[id] + e.packed[ie]
	    	s2 += 5 * it.current_id
	    end
	    @test s1 == s2 == 5*(6+12)
    	s1 = 0
    	s2 = 0
    	it = zip(a, b, c, d, exclude=(e,))
    	for (ia, ib, ic, id) in it
	    	s1 += a.packed[ia] + b.packed[ib] + c.packed[ic] + d.packed[id]
	    	s2 += 4 * it.current_id
	    end
	    @test s1 == s2 == 4*24
	end

end 
