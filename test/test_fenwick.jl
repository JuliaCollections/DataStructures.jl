@testset "Fenwick Tree" begin
    @testset "initialisation" begin
        F1 = FenwickTree{Int}()
        @test bit(F1) == Int[]
        @test size(F1) == 0
        
        F2 = FenwickTree{Float64}(5)
        z = zero(Float64)
        @test bit(F2) == [z, z, z, z, z]
        @test size(F2) == 5
    end
    
    @testset "Point update and Point queries" begin
        F1 = FenwickTree{Int}(10)
        update(F1,10, 5)
        @test getsum(F1, 10) == 5
        @test getsum(F1, 9) == 0
        @test getsum(F1, 1) == 0
    end
    
    @testset "Range update and Point queries" begin
        F1 = FenwickTree{Int}(15)
        update(F1, 2, 10, 3)
        @test getsum(F1, 1) == 0
        @test getsum(F1, 2) == 3
        @test getsum(F1, 5) == 3
        @test getsum(F1, 10) == 3
        @test getsum(F1, 11) == 0
        update(F1, 8, 13, 5)
        @test getsum(F1, 6) == 3
        @test getsum(F1, 9) == 8
        @test getsum(F1, 12) == 5
        @test getsum(F1, 14) == 0
    end
        
end
