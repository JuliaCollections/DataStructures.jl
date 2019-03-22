@testset "Fenwick Tree" begin
    @testset "initialisation" begin
        F1 = FenwickTree{Int}()
        @test bit(F1) == Int[]
        @test length(F1) == 0
        
        F2 = FenwickTree{Float64}(5)
        z = zero(Float64)
        @test bit(F2) == [z, z, z, z, z]
        @test length(F2) == 5
        
        arr = [1.2, 8.7, 7.2, 3.5]
        F3 = FenwickTree(arr)
        @test F3[1] == 1.2
        @test length(F3) == size(arr)[1]
    end
    
    @testset "Point update and Point queries" begin
        F1 = FenwickTree{Int}(10)
        update!(F1, 10, 5)
        @test sum(F1, 10) == 5
        @test sum(F1, 9) == 0
        @test sum(F1, 1) == 0
        update!(F1, 5, 7)
        @test sum(F1, 8) == 7
        @test sum(F1, 10) == 12
        @test sum(F1, 5) == 7
        @test sum(F1, 4) == 0
    end
    
    @testset "Range update and Point queries" begin
        F1 = FenwickTree{Int}(15)
        update!(F1, 2, 10, 3)
        @test sum(F1, 1) == 0
        @test sum(F1, 2) == 3
        @test sum(F1, 5) == 3
        @test sum(F1, 10) == 3
        @test sum(F1, 11) == 0
        update!(F1, 8, 13, 5)
        @test sum(F1, 6) == 3
        @test sum(F1, 9) == 8
        @test sum(F1, 12) == 5
        @test sum(F1, 14) == 0
    end
        
end