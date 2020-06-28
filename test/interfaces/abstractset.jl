"""
    testsuite(XSet, ::Type{AbstractSet})

For a type XSet test that it meets all the standard interfaces required for a subtype of
`AbstractSet`.
"""
function testsuite(XSet::Type{<:AbstractSet}, ::Type{AbstractSet})
    @testset "AbstractSet testsuite, $XSet" begin
        @testset "Construction, collect" begin
            data_in = (1,5,100)
            s = XSet(data_in)
            data_out = collect(s)
            @test all(map(d->in(d,data_out), data_in))
            @test length(data_out) == length(data_in)
        end

        @testset "eltype, empty" begin
            @test eltype(XSet()) == Int
            @test eltype(typeof(XSet())) == Int
            @test isequal(empty(XSet([1,2,3])), XSet())
        end

        @testset "Core Functionality" begin
            s = XSet([1,2,10,20,200,300,1000,10000,10002])
            @test last(s) == 10002
            @test first(s) == 1
            @test length(s) == 9
            @test pop!(s) == 10002
            @test length(s) == 8
            @test popfirst!(s) == 1
            @test length(s) == 7
            @test !in(1,s)
            @test !in(10002,s)
            @test sin(10000,s)
            @test_throws ArgumentError first(XSet())
            @test_throws ArgumentError last(XSet())
            t = copy(s)
            s = XSet()
            push!(s, 1, 2, 100)
            @test 1 in s
            @test !(3 in s)
            @test 2 in s
            @test 100 in s
            @test !(101 in s)
            @test !(1000 in s)
            @test first(s) == 1
            @test last(s) == 100
            @test s == XSet([1, 2, 100])
            push!(s, 1000)
            @test [i for i in s] == [1, 2, 100, 1000]
            @test pop!(s) == 1000
            @test s == XSet([1, 2, 100])
            push!(s, 5000)
            push!(s, 2000)
            pop!(s, 5000)
            b = 1:1000
            s = XSet(b)
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
            @test setdiff(XSet([1, 2, 3, 4]), XSet([2, 4, 5, 6])) == XSet([1, 3])
        end

        @testset "setdiff!" begin
            s2 = XSet([1, 2, 3, 4])
            setdiff!(s2, XSet([2, 4, 5, 6]))

            @test s2 == XSet([1, 3])
        end

        @testset "issue #7851" begin
            @test_throws DomainError XSet(-1)
            @test !(-1 in XSet(1:10))
        end
        @testset "Copy, copy!, empty" begin
            s1 = XSet([1,2,3])
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
            s1 = XSet()
            @test_throws DomainError push!(s1, -1)
            push!(s1, 1, 10, 100, 1000)
            @test collect(s1) == [1, 10, 100, 1000]
            push!(s1, 606)
            @test collect(s1) == [1, 10, 100, 1000, 606]
            s2 = XSet()
            @test s2 === union!(s2, s1)
            s3 = XSet([1, 10, 100])
            union!(s3, [1, 606, 1000])
            s4 = union(XSet([1, 100, 1000]), XSet([10, 100, 606]))
            @test s1 == s2 == s3 == s4
        end

        @testset "pop!, delete!" begin
            s = XSet(1:2:10)
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
            @test isempty(intersect(XSet()))
            @test isempty(intersect(XSet(1:10), XSet()))
            @test isempty(intersect(XSet(), XSet(1:10)))

            @test intersect(XSet([1,2,3])) == XSet([1,2,3])

            @test intersect(XSet(1:7), XSet(3:10)) ==
                  intersect(XSet(3:10), XSet(1:7)) == XSet(3:7)

            @test intersect!(XSet(1:10), XSet(1:4), 1:5, [1,2,10]) == XSet(1:2)
        end

        @testset "Setdiff" begin
            s1 = XSet(1:100)
            setdiff!(s1, XSet(1:2:100))
            s2 = setdiff(XSet(1:100), XSet(1:2:100))
            @test s1 == s2 == XSet(2:2:100)

            s1 = XSet(1:10)
            s2 = XSet([1:2; 6:100])
            @test setdiff(s1, s2) == setdiff(s1, [1:2; 6:100]) == XSet(3:5)
        end

        @testset "Subsets, equality" begin
            @test XSet(2:2:10) < XSet(1:10)
            @test !(XSet(2:2:10) < XSet(2:2:10))
            @test XSet(2:2:10) <= XSet(2:10)
            @test XSet(2:2:10) <= XSet(2:2:10)
        end
    end
end
