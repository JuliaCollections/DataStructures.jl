@testset "Fenwick Tree" begin
    @testset "initialisation" begin
        f1 = FenwickTree{Int}()
        @test f1.bi_tree == Int[]
        @test length(f1) == 0
        
        f2 = FenwickTree{Float64}(5)
        z = zero(Float64)
        @test f2.bi_tree == [z, z, z, z, z]
        @test length(f2) == 5
        
        arr = [1.2, 8.7, 7.2, 3.5]
        f3 = FenwickTree(arr)
        @test f3[1] == 1.2
        @test length(f3) == size(arr)[1]
    end
    
    @testset "Point update and Point queries" begin
        f1 = FenwickTree{Int}(10)
        inc!(f1, 10, 5)
        @test prefixsum(f1, 10) == 5
        @test prefixsum(f1, 9) == 0
        @test prefixsum(f1, 1) == 0
        inc!(f1, 5, 7)
        @test prefixsum(f1, 8) == 7
        @test prefixsum(f1, 10) == 12
        @test prefixsum(f1, 5) == 7
        @test prefixsum(f1, 4) == 0
    end
    
    @testset "Range update and Point queries" begin
        f1 = FenwickTree{Int}(15)
        inc!(f1, 2:10, 3)
        @test prefixsum(f1, 1) == 0
        @test prefixsum(f1, 2) == 3
        @test prefixsum(f1, 5) == 3
        @test prefixsum(f1, 10) == 3
        @test prefixsum(f1, 11) == 0
        inc!(f1, 8:13, 5)
        @test prefixsum(f1, 6) == 3
        @test prefixsum(f1, 9) == 8
        @test prefixsum(f1, 12) == 5
        @test prefixsum(f1, 14) == 0
    end
        
end