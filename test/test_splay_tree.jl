@testset "SplayTree" begin
    @testset "pushing values" begin
        t = SplayTree{Int}()
        for i in 1:100
            push!(t, i)
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
        t = SplayTree{Int}()
        for i in 1:100
            push!(t, i)
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
            push!(t, i)
        end

        @test length(t) == 100
    end

    @testset "handling different cases of delete!" begin
        t2 = SplayTree()
        for i in 1:100000
            push!(t2, i)
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

    @testset "handling different cases of push!" begin
        nums = rand(1:100000, 1000)
        t3 = SplayTree()
        uniq_nums = Set(nums)
        for num in nums
            push!(t3, num)
        end
        @test length(t3) == length(uniq_nums)
    end

    @testset "in" begin
        t4 = SplayTree{Char}()
        push!(t4, 'a')
        push!(t4, 'b')
        @test length(t4) == 2
        @test in('a', t4)
        @test !in('c', t4)
    end

    @testset "search_node" begin 
        t5 = SplayTree()
        for i in 1:32
            push!(t5, i)
        end
        n1 = search_node(t5, 21)
        @test n1.data == 21
        n2 = search_node(t5, 35)
        @test n2.data == 32
        n3 = search_node(t5, 0)
        @test n3.data == 1
    end 

    @testset "getindex" begin 
        t6 = SplayTree{Int}()
        for i in 1:10
            push!(t6, i)
        end
        for i in 1:10
            @test t6[i] == i
        end
        @test_throws KeyError getindex(t6, 0)
        @test_throws KeyError getindex(t6, 11)
    end

    @testset "key conversion in push!" begin
        t7 = SplayTree{Int}()
        push!(t7, Int8(1))
        @test length(t7) == 1
        @test haskey(t7, 1)
    end

    @testset "maximum_node" begin
        t8 = SplayTree()
        @test maximum_node(t8.root) == nothing
        for i in 1:32
            push!(t8, i)
        end
        m1 = maximum_node(t8.root)
        @test m1.data == 32
        node = t8.root
        while node.rightChild != nothing
            m = maximum_node(node.rightChild)
            @test m == m1
            node = node.rightChild
        end
    end
end