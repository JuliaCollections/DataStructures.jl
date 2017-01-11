using DataStructures, Compat
using Compat: String
if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

@testset "CircularDeque" begin
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
    @test shift!(D) === 1
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
    unshift!(D, 7)
    @test front(D) === 7
    @test back(D) === 5
    @test_throws BoundsError unshift!(D, 8)
    @test shift!(D) === 7
    @test shift!(D) === 2
    @test pop!(D) === 5
    @test shift!(D) === 3
    @test pop!(D) === 4
    @test_throws BoundsError pop!(D)
    @test_throws BoundsError shift!(D)
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
    @test shift!(D) == 1
    push!(D, 6)
    for i = 2:6
        @test back(D) === 6
        @test D[1] === i
        @test D[7-i] === 6
        @test shift!(D) === i
    end

    # Test that unshift! works on an empty deque, and that front/back give the right answer
    D = CircularDeque{Int}(5)
    unshift!(D, 30)
    @test front(D) == back(D) == 30
    empty!(D)
    unshift!(D, 40)
    @test front(D) == back(D) == 40

    # Test iteration over loop
    D = CircularDeque{Int}(5)
    for i in 1:5 push!(D, i) end
    @test collect([i for i in D]) == collect(1:5)
end

nothing
