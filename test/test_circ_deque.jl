@testset "CircularDeque" begin

    @testset "Core Functionality" begin
        D = CircularDeque{Int}(5)
        @test eltype(D) == Int
        @test capacity(D) == 5
        @test length(D) == 0
        @test isempty(D)
        @test_throws BoundsError front(D)
        @test_throws BoundsError back(D)
        push!(D, 1)
        @test front(D) === back(D) === 1
        push!(D, 2)
        @test front(D) === 1
        @test back(D)  === 2
        @test length(D) == 2
        for i = 3:5
            push!(D, i)
        end
        @test_throws BoundsError push!(D, 6)
        @test popfirst!(D) === 1
        @test front(D) === 2
        @test back(D) === 5
        io = IOBuffer()
        print(io, Int)
        intstr = String(take!(io))
        print(io, D)
        @test String(take!(io)) == "CircularDeque{$intstr}([2,3,4,5])"
        push!(D, 6)
        @test front(D) === 2
        @test back(D) === 6
        @test pop!(D) === 6
        @test front(D) === 2
        @test back(D) === 5
        pushfirst!(D, 7)
        @test front(D) === 7
        @test back(D) === 5
        @test_throws BoundsError pushfirst!(D, 8)
        @test popfirst!(D) === 7
        @test popfirst!(D) === 2
        @test pop!(D) === 5
        @test popfirst!(D) === 3
        @test pop!(D) === 4
        @test_throws BoundsError pop!(D)
        @test_throws BoundsError popfirst!(D)
        @test isempty(D)
        push!(D, 10)
        @test !isempty(D)
        empty!(D)
        @test isempty(D)
        @test_throws BoundsError front(D)
        push!(D, 20)
        @test front(D) == back(D) == 20
        empty!(D)
        for i = 1:5
            push!(D, i)
        end
        @test popfirst!(D) == 1
        push!(D, 6)
        for i = 2:6
            @test back(D) === 6
            @test D[1] === i
            @test D[7-i] === 6
            @test popfirst!(D) === i
        end
    end
    
    @testset "pushfirst! works on an empty deque" begin
        # Test that pushfirst! works on an empty deque, and that front/back give the right answer
        D = CircularDeque{Int}(5)
        pushfirst!(D, 30)
        @test front(D) == back(D) == 30
        empty!(D)
        pushfirst!(D, 40)
        @test front(D) == back(D) == 40
    end

    @testset "iteration over loop" begin
        D = CircularDeque{Int}(5)
        for i in 1:5 push!(D, i) end
        @test collect([i for i in D]) == collect(1:5)
    end
end

nothing
