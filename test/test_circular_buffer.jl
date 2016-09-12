using DataStructures
if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

cb = CircularBuffer{Int}(5)
@test length(cb) == 0
@test capacity(cb) == 5
# throws ArgumentError on v0.4 and BoundsError on v0.5 (diverged at 0.5.0-dev+5230)
if VERSION >= v"0.5.0-dev+5230"
    @test_throws BoundsError first(cb)
else
    @test_throws ArgumentError first(cb)
end
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
