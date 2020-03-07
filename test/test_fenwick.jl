@testset "Fenwick Tree" begin
    @testset "initialisation" begin
        f1 = FenwickTree{Float64}(5)
        @test f1.bi_tree == zeros(5)
        @test length(f1) == 5
        @test eltype(f1) == Float64
        @test eltype(typeof(f1)) == Float64

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

@testset "Suffix Fenwick Tree" begin
    @testset "initialisation" begin
        f1 = SuffixFenwickTree{Float64}(5)
        @test f1.bi_tree == zeros(5)
        @test length(f1) == 5
        @test eltype(f1) == Float64
        @test eltype(typeof(f1)) == Float64
        
        arr = [1.2, 8.7, 7.2, 3.5]
        f2 = SuffixFenwickTree(arr)
        @test f2[1] == sum(arr) 
        @test length(f2) == 4
        @test [f2[i] for i = 1 : length(f2)] == reverse(cumsum(reverse(arr)))
    end
    
    @testset "Point update and Point queries" begin
        f1 = SuffixFenwickTree{Int}(10)
        
        inc!(f1, 10, 5)
        @test suffixsum(f1, 10) == 5
        @test suffixsum(f1, 9) == 5
        @test suffixsum(f1, 1) == 5
        
        inc!(f1, 5, 7)
        @test suffixsum(f1, 8) == 5
        @test suffixsum(f1, 10) == 5
        @test suffixsum(f1, 5) == 12
        @test suffixsum(f1, 4) == 12
        
        dec!(f1, 7, 2)
        @test suffixsum(f1, 8) == 5
        @test suffixsum(f1, 6) == 3
           
        @test_throws ArgumentError inc!(f1, 11)
        @test_throws ArgumentError inc!(f1, 0)
    end
    
    @testset "resize" begin
        f1 = SuffixFenwickTree{Int}(10)
        @test_throws ArgumentError resize!(f1, 0)
        
        resize!(f1, 5)
        @test length(f1) == 5
        
        resize!(f1, 15)
        @test length(f1) == 15 
        
        arr = [1.2, 8.7, 7.2, 3.5]
        f2 = SuffixFenwickTree(arr)
        
        resize!(f2, 6)
        @test length(f2) == 6
        @test f2[5] == 0
        @test f2[1] == sum(arr)
        
        resize!(f2, 3)
        @test length(f2) == 3
        @test [f2[i] for i = 1 : 3] == reverse(cumsum(reverse(arr[1:3])))
    end
end