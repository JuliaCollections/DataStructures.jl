@testset "CircularBuffer" begin
    cb = CircularBuffer{Int}(5)
    @test length(cb) == 0
    @test capacity(cb) == 5
    @test_throws BoundsError first(cb)
    @test isempty(cb) == true
    @test isfull(cb) == false

    push!(cb, 1)
    @test length(cb) == 1
    @test capacity(cb) == 5
    @test isfull(cb) == false

    append!(cb, 2:8)
    @test length(cb) == capacity(cb)
    @test size(cb) == (length(cb),)
    @test isempty(cb) == false
    @test isfull(cb) == true
    @test convert(Array, cb) == Int[4,5,6,7,8]
    @test cb[1] == 4
    @test cb[2] == 5
    @test cb[3] == 6
    @test cb[4] == 7
    @test cb[5] == 8
    @test_throws BoundsError cb[6]
    @test_throws BoundsError cb[3:6]
    @test cb[3:4] == Int[6,7]
    @test cb[[1,5]] == Int[4,8]

    cb[3] = 999
    @test convert(Array, cb) == Int[4,5,999,7,8]

    # Test pushfirst
    cb = CircularBuffer{Int}(5)  # New, empty one for full test coverage
    for i in -5:5
        pushfirst!(cb, i)
    end
    arr = convert(Array, cb)
    @test arr == Int[5, 4, 3, 2, 1]
    for (idx, n) in enumerate(5:1)
        @test arr[idx] == n
    end
    # Issue 379
    cb = CircularBuffer{Int}(5)
    pushfirst!(cb, 1)
    @test cb == [1]
    pushfirst!(cb, 2)
    @test cb == [2, 1]

    # test empty!(cb)
    @test length(empty!(cb)) == 0

    # test pop!(cb)
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

    # test popfirst!(cb)
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
