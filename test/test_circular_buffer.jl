@testset "CircularBuffer" begin

    @testset "Core Functionality" begin
        cb = CircularBuffer{Int}(5)
        @testset "When empty" begin
            @test length(cb) == 0
            @test capacity(cb) == 5
            @test_throws BoundsError first(cb)
            @test_throws BoundsError last(cb)
            @test isempty(cb) == true
            @test isfull(cb) == false
            @test eltype(cb) == Int
            @test eltype(typeof(cb)) == Int
        end

        @testset "With 1 element" begin
            push!(cb, 1)
            @test length(cb) == 1
            @test capacity(cb) == 5
            @test isfull(cb) == false
            @test first(cb) == last(cb)
        end

        @testset "Appending many elements" begin
            append!(cb, 2:8)
            @test length(cb) == capacity(cb)
            @test size(cb) == (length(cb),)
            @test isempty(cb) == false
            @test isfull(cb) == true
            @test convert(Array, cb) == Int[4,5,6,7,8]
        end

        @testset "getindex" begin
            @test cb[1] == 4
            @test cb[2] == 5
            @test cb[3] == 6
            @test cb[4] == 7
            @test cb[5] == 8
            @test_throws BoundsError cb[6]
            @test_throws BoundsError cb[3:6]
            @test cb[3:4] == Int[6,7]
            @test cb[[1,5]] == Int[4,8]
            @test first(cb) == 4
            @test last(cb) == 8
        end

        @testset "setindex" begin
            cb[3] = 999
            @test convert(Array, cb) == Int[4,5,999,7,8]
        end
    end

    @testset "other constructor" begin
        cb = CircularBuffer(10)
        @test length(cb) == 0
        @test typeof(cb) <: CircularBuffer{Any}
    end

    @testset "pushfirst" begin
        cb = CircularBuffer{Int}(5)  # New, empty one for full test coverage
        for i in -5:5
            pushfirst!(cb, i)
        end
        arr = convert(Array, cb)
        @test arr == Int[5, 4, 3, 2, 1]
        for (idx, n) in enumerate(5:1)
            @test arr[idx] == n
        end
    end

    @testset "Issue 429" begin
        cb = CircularBuffer{Int}(5)
        map(x -> pushfirst!(cb, x), 1:8)
        pop!(cb)
        pushfirst!(cb, 9)
        @test length(cb.buffer) == cb.capacity
        arr = convert(Array, cb)
        @test arr == Int[9, 8, 7, 6, 5]
    end

    @testset "Issue 379" begin
        cb = CircularBuffer{Int}(5)
        pushfirst!(cb, 1)
        @test cb == [1]
        pushfirst!(cb, 2)
        @test cb == [2, 1]
    end

    @testset "empty!" begin
        cb = CircularBuffer{Int}(5)
        push!(cb, 13)
        empty!(cb)
        @test length(cb) == 0
    end

    @testset "pop!" begin
        cb = CircularBuffer{Int}(5)
        for i in 0:5    # one extra to force wraparound
            push!(cb, i)
        end
        for j in 5:-1:1
            @test pop!(cb) == j
            @test convert(Array, cb) == collect(1:j-1)
        end
        @test isempty(cb)
        @test_throws ArgumentError pop!(cb)
    end

    @testset "popfirst!" begin
        cb = CircularBuffer{Int}(5)
        for i in 0:5    # one extra to force wraparound
            push!(cb, i)
        end
        for j in 1:5
            @test popfirst!(cb) == j
            @test convert(Array, cb) == collect(j+1:5)
        end
        @test isempty(cb)
        @test_throws ArgumentError popfirst!(cb)
    end

    @testset "fill!" begin
        @testset "fill an empty buffer" begin
            cb = CircularBuffer{Int}(3)
            fill!(cb, 42)
            @test Array(cb) == [42, 42, 42]
        end
        @testset "fill a non empty buffer" begin
            cb = CircularBuffer{Int}(3)
            push!(cb, 21)
            fill!(cb, 42)
            @test Array(cb) == [21, 42, 42]
        end
    end
end
