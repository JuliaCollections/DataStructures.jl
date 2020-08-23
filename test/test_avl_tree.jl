@testset "AVLTree" begin
    @testset "inserting values" begin
        t = AVLTree{Int}()
        for i in 1:100
            insert!(t, i)
        end

        @test length(t) == 100

        for i in 1:100
            @test haskey(t, i)
        end

        for i = 101:200
            @test !haskey(t, i)
        end
    end

    @testset "deleting values" begin
        t = AVLTree{Int}()
        for i in 1:100
            insert!(t, i)
        end
        for i in 1:2:100
            delete!(t, i)
        end

        @test length(t) == 50
        
        for i in 1:100
            if iseven(i)
                @test haskey(t, i)
            else
                @test !haskey(t, i)
            end
        end

        for i in 1:2:100
            insert!(t, i)
        end

        @test length(t) == 100
    end

    @testset "handling different cases of delete!" begin
        t2 = AVLTree()
        for i in 1:100000
            insert!(t2, i)
        end

        @test length(t2) == 100000
        
        nums = rand(1:100000, 8599)
        visited = Set()
        for num in nums 
            if !(num in visited)
                delete!(t2, num)
                push!(visited, num) 
            end
        end

        for i in visited
            @test !haskey(t2, i)
        end
        @test (length(t2) + length(visited)) == 100000
    end

    @testset "handling different cases of insert!" begin
        nums = rand(1:100000, 1000)
        t3 = AVLTree()
        uniq_nums = Set(nums)
        for num in uniq_nums
            insert!(t3, num)
        end
        @test length(t3) == length(uniq_nums)
    end

end