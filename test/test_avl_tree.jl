include("../src/avl_tree.jl")
@testset "AVLTree" begin
    t = AVLTree()
    for i = 1:10000
    	insert!(t, i)
    end
    for i = 1:10000
    	@test search_key(t, i)
    end

    for i = 10001:20000
        @test !search_key(t, i)
    end

    for i = 1:2:10000
    	delete!(t, i)
    end

    for i = 1:10000
    	if iseven(i)
    		@test search_key(t, i)
    	else
    		@test !search_key(t, i)
    		@test_throws KeyError delete!(t, i)
    	end
    end

    for i = 1:2:1000
        insert!(t, i)
    end

    for i = 1:1000
        @test search_key(t, i)
    end

    # for handling cases related to delete!
    t2 = AVLTree{Int}()
    for i = 1:100000
        insert!(t2, i)
    end

    nums = rand(1:100000, 1000)
    visited = Set{Int}()
    for num in nums 
        if num in visited
            @test_throws KeyError delete!(t2, num)
        else
            delete!(t2, num)
            push!(visited, num) 
        end
    end

    for i = 1:100000
        if i in visited
            @test !search_key(t2, i)
        else
            @test search_key(t2, i)
        end
    end

end