include("../src/red_black_tree.jl")
@testset "RBTree" begin
    t = RBTree{Int}()
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

    # test hash
    for i = 1:1000
        node = search_node(t, i)
        @test hash(node) == hash(i, hash(node.color))
    end

    # for handling cases related to delete!
    t2 = RBTree()
    for i = 1:100000
        insert!(t2, i)
    end

    nums = rand(1:100000, 1000)
    visited = Set()
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

    # for handling cases related to insert!
    t3 = RBTree()
    for num in nums
        insert!(t3, num)
    end

    for i in visited
        @test search_key(t3, i)
    end

end