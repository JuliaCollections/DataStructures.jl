@testset "AVLTree" begin
    @testset "inserting values" begin
        t = AVLTree{Int}()
        for i in 100:-1:1
            insert!(t, i)
        end

        @test length(t) == 100

        for i in 1:100
            @test haskey(t, i)
        end

        for i = 101:150
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
        t2 = AVLTree{Int}()
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
        t3 = AVLTree{Int}()
        uniq_nums = Set(nums)
        for num in uniq_nums
            insert!(t3, num)
        end
        @test length(t3) == length(uniq_nums)
    end

    @testset "in" begin
        t4 = AVLTree{Char}()
        push!(t4, 'a')
        push!(t4, 'b')
        @test length(t4) == 2
        @test in('a', t4)
        @test !in('c', t4)
    end

    @testset "search_node" begin
        t5 = AVLTree{Int}()
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
        t6 = AVLTree{Int}()
        for i in 1:10
            push!(t6, i)
        end
        for i in 1:10
            @test getindex(t6, i) == i
        end
        @test_throws BoundsError getindex(t6, 0)
        @test_throws BoundsError getindex(t6, 11)
    end

    @testset "key conversion in push!" begin
        t7 = AVLTree{Int}()
        push!(t7, Int8(1))
        @test length(t7) == 1
        @test haskey(t7, 1)
    end

    @testset "maximum and minimum" begin
        t8 = AVLTree{Int}()
        for i in 1:32
            push!(t8, i)
        end
        @test minimum(t8) == 1
        @test maximum(t8) == 32
        delete!(t8, 32)
        @test maximum(t8) == 31
        delete!(t8, 1)
        @test minimum(t8) == 2
        delete!(t8, 20)
        delete!(t8, 18)
        delete!(t8, 5)
        delete!(t8, 25)
        @test maximum(t8) == 31
        @test minimum(t8) == 2
    end

    @testset "minimum_node" begin
        t9 = AVLTree{Int}()
        @test minimum_node(t9.root) == nothing
        for i in 1:32
            push!(t9, i)
        end
        m1 = minimum_node(t9.root)
        @test m1.data == 1
        node = t9.root
        while node.leftChild != nothing
            m = minimum_node(node.leftChild)
            @test m == m1
            node = node.leftChild
        end
    end

    @testset "rank" begin
        t10 = AVLTree{Int}()
        for i in 1:20
            push!(t10, i)
        end
        for i in 1:20
            @test sorted_rank(t10, i) == i
        end
        @test_throws KeyError sorted_rank(t10, 21)
    end
end
