@testset "DisjointSet" begin

    @testset "IntDisjointSets" begin
        for T in [Int, UInt8, Int8, UInt16, Int16, UInt32, Int32, UInt64]
            @testset "eltype = $(T)" begin
                s = IntDisjointSets(T(10))
                s2 = IntDisjointSets{T}(10)

                @testset "basic tests" begin
                    @test length(s) == 10
                    @test length(s2) == 10
                    @test eltype(s) == T
                    @test eltype(s2) == T
                    @test eltype(typeof(s)) == T
                    @test eltype(typeof(s2)) == T
                    @test num_groups(s) == T(10)
                    @test num_groups(s2) == T(10)

                    for i = 1:10
                        @test find_root!(s, T(i)) == T(i)
                    end
                    @test_throws BoundsError find_root!(s, T(11))

                    @test !in_same_set(s, T(2), T(3))
                end

                @testset "union!" begin
                    union!(s, T(2), T(3))
                    @test num_groups(s) == T(9)
                    @test in_same_set(s, T(2), T(3))
                    @test find_root!(s, T(3)) == T(2)
                    union!(s, T(3), T(2))
                    @test num_groups(s) == T(9)
                    @test in_same_set(s, T(2), T(3))
                    @test find_root!(s, T(3)) == T(2)
                end

                @testset "more tests" begin
                    # We cannot support arbitrary indexing and still use @inbounds with IntDisjointSets
                    # (and it's not useful anyway)
                    @test_throws MethodError push!(s, T(22))

                    @test push!(s) == T(11)
                    @test num_groups(s) == T(10)

                    @test union!(s, T(8), T(7)) == T(8)
                    @test union!(s, T(5), T(6)) == T(5)
                    @test union!(s, T(8), T(5)) == T(8)
                    @test num_groups(s) == T(7)
                    @test find_root!(s, T(6)) == T(8)
                    union!(s, T(2), T(6))
                    @test find_root!(s, T(2)) == T(8)
                    root1 = find_root!(s, T(6))
                    root2 = find_root!(s, T(2))
                    @test root_union!(s, T(root1), T(root2)) == T(8)
                    @test union!(s, T(5), T(6)) == T(8)
                end
            end
        end
    end

    @testset "IntDisjointSets overflow" begin
        for T in [UInt8, Int8]
            s = IntDisjointSets(T(typemax(T)-1))
            push!(s)
            @test_throws ArgumentError push!(s)
        end
    end

    @testset "DisjointSets" begin
        # DisjointSets supports arbitrary indices
        s = DisjointSets{Int}(1:10)

        @testset "constructor" begin
            @test DisjointSets() isa DisjointSets{Any}
            @test DisjointSets{Int}(1:10) isa DisjointSets{Int}
            @test DisjointSets{Float64}(1.0:10.0...) isa DisjointSets{Float64}
            @test DisjointSets(collect(1:10)) isa DisjointSets{Int}
            @test DisjointSets(collect(1.0:10.0)...) isa DisjointSets{Float64}
            @test DisjointSets(x*im for x = 1:10) isa DisjointSets{Complex{Int}}
            g = (x % 2 == 0 ? x+1//x : x*im for x = 1:10)
            @test DisjointSets(g) isa DisjointSets{Number}
        end

        @testset "basic tests" begin
            @test length(s) == 10
            @test num_groups(s) == 10
            @test eltype(s) == Int
            @test eltype(typeof(s)) == Int
            @test length(empty(s)) == num_groups(empty(s)) == 0
            @test empty(s) isa DisjointSets{eltype(s)}
            @test collect(s) == collect(1:10)
            g = (x % 2 == 0 ? x+1//x : x*im for x = 1:10)
            s1 = DisjointSets(g)
            @test length(s1) == 10
            @test sizehint!(s1, 100) === s1

            r = [find_root!(s, i) for i in 1 : 10]
            @test isequal(r, collect(1:10))
        end

        @testset "union!" begin
            for i = 1 : 5
                x = 2 * i - 1
                y = 2 * i
                union!(s, x, y)
                @test find_root!(s, x) == find_root!(s, y)
            end


            @test union!(s, 1, 4) == find_root!(s, 1)
            @test union!(s, 3, 5) == find_root!(s, 1)
            @test union!(s, 7, 9) == find_root!(s, 7)

            @test length(s) == 10
            @test num_groups(s) == 2
        end

        @testset "r0" begin
            r0 = [ find_root!(s,i) for i in 1:10 ]
            # Since this is a DisjointSet (not IntDisjointSet), the root for 17 will be 17, not 11
            push!(s, 17)

            @test length(s) == 11
            @test num_groups(s) == 3

            r0 = [ r0 ; 17]
            r = [find_root!(s, i) for i in [1 : 10; 17] ]
            @test isequal(r, r0)
        end

        @testset "root_union!" begin
            root1 = find_root!(s, 7)
            root2 = find_root!(s, 3)
            @test root1 != root2
            root_union!(s, 7, 3)
            @test find_root!(s, 7) == find_root!(s, 3)
        end

        @testset "Some tests using non-integer disjoint sets" begin
            elems = ["a", "b", "c", "d"]
            a = DisjointSets{AbstractString}(elems)
            @test collect(a) == ["a", "b", "c", "d"]
            union!(a, "a", "b")
            @test in_same_set(a,"a","b")
            @test find_root!(a,"a") == find_root!(a,"b")
            @test find_root!(a,"a") in elems
            @test !in_same_set(a, "c", "d")
            # union returns new root
            @test find_root!(a,"a") == union!(a,"b","c")
            union!(a,"c","d")
            # Now they should be in same set, and a is transitively connected to d
            @test in_same_set(a,"a", "d")
            # Root element should thus be same for all:
            @test all(find_root!(a,first(elems)) .== map(x->find_root!(a,x),elems))

            #@test_throws KeyError find_root!(a,"f")

            push!(a, "f")
            @test find_root!(a,"a") != find_root!(a,"f")
        end
    end

end # @testset DisjointSet
