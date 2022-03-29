@testset "segment_tree" begin
    @testset "Add" begin
        X1 = segment_tree(100,UInt64,Base.:+)
        a = zeros(UInt64, 100)
        change_range!(X1, 3,37,53)
        change_range!(X1, 9,23,45)
        change_range!(X1, 5,2,21)
        a[37:53] .= 3
        a[23:45] .= 9
        a[2:21]  .= 5
        @test sum(a[23:99]) == get_range(X1, 23,99)
        @test sum(a[55:87]) == get_range(X1, 55,87)
        @test sum(a[2:3]) == get_range(X1, 2, 3)
        @test sum(a[5:77]) == get_range(X1, 5,77)
    end

    @testset "Large_randomized_trial" begin
        X1 = segment_tree(10000,UInt64, Base.:+)
        X2 = zeros(UInt64, 10000)
        for i in 1:10000
            a = rand(1:10000)
            b = rand(a:10000)
            c = rand(UInt64)
            change_range!(X1,c,a,b)
            X2[a:b] = c
            d = rand(1:10000)
            e = rand(d:10000)
            @test sum(X2[d:e]) == get_range(X1,d,e)
        end
    end

end