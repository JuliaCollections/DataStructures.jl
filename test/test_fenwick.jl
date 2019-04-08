@testset "Fenwick Tree" begin
    @testset "initialisation" begin
        f1 = FenwickTree{Float64}(5)
        @test f1.bi_tree == zeros(5)
        @test length(f1) == 5
        
        arr = [1.2, 8.7, 7.2, 3.5]
        f3 = FenwickTree(arr)
        @test f3[1] == 1.2
        @test length(f3) == length(arr)
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
        
        dec!(f1, 7, 2)
        @test prefixsum(f1, 8) == 5
        @test prefixsum(f1, 6) == 7
        
        incdec!(f1, 2, 6, 3)
        @test prefixsum(f1, 3) == 3
        @test prefixsum(f1, 7) == 5
        
        @test_throws ArgumentError inc!(f1, 11)
        @test_throws ArgumentError inc!(f1, 0)
    end
    
end