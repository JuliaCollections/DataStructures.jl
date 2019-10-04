@testset "DisjointSet" begin

    @testset "IntDisjointSets" begin
        s = IntDisjointSets(10)

        @testset "basic tests" begin
            @test length(s) == 10
            @test eltype(s) == Int
            @test eltype(typeof(s)) == Int
            @test num_groups(s) == 10

            for i = 1:10
                @test find_root(s, i) == i
            end
            @test_throws BoundsError find_root(s, 11)

            @test !in_same_set(s, 2, 3)
        end

        @testset "union!" begin
            union!(s, 2, 3)
            @test num_groups(s) == 9
            @test in_same_set(s, 2, 3)
            @test find_root(s, 3) == 2
            union!(s, 3, 2)
            @test num_groups(s) == 9
            @test in_same_set(s, 2, 3)
            @test find_root(s, 3) == 2
        end

        @testset "more tests" begin
            # We cannot support arbitrary indexing and still use @inbounds with IntDisjointSets
            # (and it's not useful anyway)
            @test_throws MethodError push!(s, 22)

            @test push!(s) == 11
            @test num_groups(s) == 10

            @test union!(s, 8, 7) == 8
            @test union!(s, 5, 6) == 5
            @test union!(s, 8, 5) == 8
            @test num_groups(s) == 7
            @test find_root(s, 6) == 8
            union!(s, 2, 6)
            @test find_root(s, 2) == 8
            root1 = find_root(s, 6)
            root2 = find_root(s, 2)
            @test root_union!(s, root1, root2) == 8
            @test union!(s, 5, 6) == 8
        end
    end

    @testset "DisjointSets" begin
        # DisjointSets supports arbitrary indices
        s = DisjointSets{Int}(1:10)

        @testset "basic tests" begin
            @test length(s) == 10
            @test num_groups(s) == 10
            @test eltype(s) == Int
            @test eltype(typeof(s)) == Int

            r = [find_root(s, i) for i in 1 : 10]
            @test isequal(r, collect(1:10))
        end

        @testset "union!" begin
            for i = 1 : 5
                x = 2 * i - 1
                y = 2 * i
                union!(s, x, y)
                @test find_root(s, x) == find_root(s, y)
            end


            @test union!(s, 1, 4) == find_root(s, 1)
            @test union!(s, 3, 5) == find_root(s, 1)
            @test union!(s, 7, 9) == find_root(s, 7)

            @test length(s) == 10
            @test num_groups(s) == 2
        end

        @testset "r0" begin
            r0 = [ find_root(s,i) for i in 1:10 ]
            # Since this is a DisjointSet (not IntDisjointSet), the root for 17 will be 17, not 11
            push!(s, 17)

            @test length(s) == 11
            @test num_groups(s) == 3

            r0 = [ r0 ; 17]
            r = [find_root(s, i) for i in [1 : 10; 17] ]
            @test isequal(r, r0)
        end

        @testset "root_union!" begin
            root1 = find_root(s, 7)
            root2 = find_root(s, 3)
            @test root1 != root2
            root_union!(s, 7, 3)
            @test find_root(s, 7) == find_root(s, 3)
        end

        @testset "Some tests using non-integer disjoint sets" begin
            elems = ["a", "b", "c", "d"]
            a = DisjointSets{AbstractString}(elems)
            union!(a, "a", "b")
            @test in_same_set(a,"a","b")
            @test find_root(a,"a") == find_root(a,"b")
            @test find_root(a,"a") in elems
            @test !in_same_set(a, "c", "d")
            # union returns new root
            @test find_root(a,"a") == union!(a,"b","c")
            union!(a,"c","d")
            # Now they should be in same set, and a is transitively connected to d
            @test in_same_set(a,"a", "d")
            # Root element should thus be same for all:
            @test all(find_root(a,first(elems)) .== map(x->find_root(a,x),elems))

            #@test_throws KeyError find_root(a,"f")

            push!(a, "f")
            @test find_root(a,"a") != find_root(a,"f")
        end
    end

end # @testset DisjointSet
