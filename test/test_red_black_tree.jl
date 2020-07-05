include("../src/red_black_tree.jl")
@testset "RBTree" begin
    t = RBTree()
    for i = 1:100
    	insert!(t, i)
    end
    for i = 1:100
    	@test search_key(t, i)
    end

    for i = 101:200
        @test !search_key(t, i)
    end

    for i = 1:2:100
    	delete!(t, i)
    end

    for i = 1:100
    	if iseven(i)
    		@test search_key(t, i)
    	else
    		@test !search_key(t, i)
    		@test_throws KeyError delete!(t, i)
    	end
    end

    for i = 1:2:100
        insert!(t, i)
    end

    for i = 1:100
        @test search_key(t, i)
    end

end