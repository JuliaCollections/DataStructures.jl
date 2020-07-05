include("../src/red_black_tree.jl")
@testset "RBTree" begin
    t = RBTree()
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

end