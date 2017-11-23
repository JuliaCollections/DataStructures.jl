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

    # Test unshift
    cb = CircularBuffer{Int}(5)  # New, empty one for full test coverage
    for i in -5:5
        unshift!(cb, i)
    end
    arr = convert(Array, cb)
    @test arr == Int[5, 4, 3, 2, 1]
    for (idx, n) in enumerate(5:1)
        @test arr[idx] == n
    end

    # test empty!(cb)
    @test length(empty!(cb)) == 0

    # test fill!(cb, val)
    empty!(cb)
    fill!(cb, 123)
    @test length(cb) == capacity(cb)
    for idx in 1:length(cb)
        @test cb[idx] == 123
    end

end
