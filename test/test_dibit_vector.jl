@testset "DiBitVectors" begin
    d0 = DiBitVector()
    d1 = DiBitVector(10)
    d2 = DiBitVector(10, 0)

    @test_throws ArgumentError DiBitVector(5, 4)
    @test_throws ArgumentError DiBitVector(5, -1)

    @test_throws ArgumentError DiBitVector(-5)
    @test_throws ArgumentError DiBitVector(-5, 1)

    @test length(d0) == 0
    @test isempty(d0)
    @test_throws ArgumentError pop!(d0)
    push!(d0, 1)
    @test length(d0) == 1
    @test pop!(d0) == 1
    @test length(d0) == 0
    @test_throws ArgumentError pop!(d0)

    @test length(d1) == length(d2) == 10
    @test d1 == d2
    @test all(d1 .== 0)
    @test all(d2 .== 0)

    @test size(d1) == size(d2) == (10,)

    d3 = DiBitVector(30, 3)
    @test all(d3 .== 3)
    @test d3[1] == d3[end] == 3

    push!(d3, 0)
    @test length(d3) == 31 && length(d3.data) == 1
    push!(d3, 1)
    @test length(d3) == 32 && length(d3.data) == 1
    push!(d3, 2)
    @test length(d3) == 33 && length(d3.data) == 2
    push!(d3, 3)
    @test length(d3) == 34 && length(d3.data) == 2

    @test pop!(d3) == 3
    @test length(d3) == 33 && length(d3.data) == 2
    @test pop!(d3) == 2
    @test length(d3) == 32 && length(d3.data) == 1
    @test pop!(d3) == 1
    @test length(d3) == 31 && length(d3.data) == 1
    @test pop!(d3) == 0
    @test length(d3) == 30 && length(d3.data) == 1
    @test pop!(d3) == 3
    @test length(d3) == 29 && length(d3.data) == 1

    @test zero(d3) == DiBitVector(length(d3))

    @test_throws BoundsError d3[0]
    @test_throws BoundsError d3[-1]
    @test_throws BoundsError d3[99991]
end

