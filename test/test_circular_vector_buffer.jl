@testset "CircularVectorBuffer" begin

    @testset "Core Functionality" begin
        cb = CircularVectorBuffer{Int}(5, 2)
        @testset "When empty" begin
            @test length(cb) == 0
            @test capacity(cb) == 5
            @test_throws BoundsError first(cb)
            @test isempty(cb) == true
            @test isfull(cb) == false
        end

        @testset "With 1 element" begin
            push!(cb, [1, 1])
            @test length(cb) == 2
            @test capacity(cb) == 5
            @test isfull(cb) == false
        end

        @testset "Appending many elements" begin
            append!(cb, [2:8 2:8])
            @test capacity(cb) == size(cb, 1)
            @test length(cb) == size(cb, 1) * size(cb, 2)
            @test isempty(cb) == false
            @test isfull(cb) == true
            @test convert(Matrix, cb) == Int[4:8 4:8]
        end

        @testset "getindex" begin
            @test cb[1,:] == [4, 4]
            @test cb[2,:] == [5, 5]
            @test cb[3,:] == [6, 6]
            @test cb[4,:] == [7, 7]
            @test cb[5,:] == [8, 8]
            @test_throws BoundsError cb[6,:]
            @test_throws BoundsError cb[3:6,:]
            @test cb[3:4,:] == Int[6:7 6:7]
            @test cb[[1,5],:] == Int[4 4; 8 8]
            @test cb[1] == 4
        end

        @testset "setindex" begin
            cb[3,:] .= 999
            @test convert(Array, cb) == Int[4 4; 5 5; 999 999; 7 7; 8 8]
            cb[1] = 1000
            @test convert(Array, cb) == Int[1000 4; 5 5; 999 999; 7 7; 8 8]
        end
    end


    @testset "pushfirst" begin
        cb = CircularVectorBuffer{Int}(5, 2)  # New, empty one for full test coverage
        for i in -5:5
            pushfirst!(cb, [i, i + 1])
        end
        arr = convert(Array, cb)
        @test arr == Int[5 6; 4 5; 3 4; 2 3; 1 2]
        for (idx, n) in enumerate(5:1)
            @test arr[idx, :] == [n, n + 1]
        end
    end

    @testset "Issue 429" begin
        cb = CircularVectorBuffer{Int}(5, 2)
        map(x -> pushfirst!(cb, [x, x + 1]), 1:8)
        pop!(cb)
        pushfirst!(cb, [9, 10])
        @test size(cb.buffer, 1) == cb.capacity
        arr = convert(Array, cb)
        @test arr == Int[9 10; 8 9; 7 8; 6 7; 5 6]
    end

    @testset "Issue 379" begin
        cb = CircularVectorBuffer{Int}(5, 2)
        pushfirst!(cb, [1, 2])
        @test cb == [1 2]
        pushfirst!(cb, [2, 3])
        @test cb == [2 3; 1 2]
    end

    @testset "empty!" begin
        cb = CircularVectorBuffer{Int}(5, 2)
        push!(cb, [13, 14])
        empty!(cb)
        @test length(cb) == 0
    end

    @testset "pop!" begin
        cb = CircularVectorBuffer{Int}(5, 2)
        for i in 0:5    # one extra to force wraparound
            push!(cb, [i, i + 1])
        end
        for j in 5:-1:1
            @test pop!(cb) == [j, j + 1]
            @test convert(Array, cb) == [1:j-1 2:j]
        end
        @test isempty(cb)
        @test_throws ArgumentError pop!(cb)
    end

    @testset "popfirst!" begin
        cb = CircularVectorBuffer{Int}(5, 2)
        for i in 0:5    # one extra to force wraparound
            push!(cb, [i, i + 1])
        end
        for j in 1:5
            @test popfirst!(cb) == [j, j + 1]
            @test convert(Array, cb) == [j+1:5 j+2:6]
        end
        @test isempty(cb)
        @test_throws ArgumentError popfirst!(cb)
    end

    @testset "fill!" begin
        @testset "fill an empty buffer" begin
            cb = CircularVectorBuffer{Int}(3, 2)
            fill!(cb, [42, 42])
            @test Array(cb) == ones(3,2) * 42
        end
        @testset "fill a non empty buffer" begin
            cb = CircularVectorBuffer{Int}(3, 2)
            push!(cb, [21, 22])
            fill!(cb, [42, 43])
            @test Array(cb) == [21 22; 42 43; 42 43]
        end
    end
end
