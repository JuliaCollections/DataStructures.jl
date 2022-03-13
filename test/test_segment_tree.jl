@testset "segment_tree" begin
    @testset "Add" begin
        X1 = segment_tree(100,Base.:+)
        a = zeros(Int64, 100)
        change_range!(X1, 3,37,53)
        change_range!(X1, 9,23,45)
        change_range!(X1, 5,2,21)
        a[37:53] .= 3
        a[23:45] .= 9
        a[2:21]  .= 5
        @test sum(a[23:99]) == get_range(X1, 23,99)

    end


    @testset "Large_randomized_trial" begin
        
    end

end