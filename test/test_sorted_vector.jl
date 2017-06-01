@testset "SortedVector" begin

    @testset "With standard ordering" begin

        v = SortedVector([5, 2])
        @test v.data == [2, 5]

        push!(v, 3)
        @test v.data == [2, 3, 5]

        push!(v, 4, 6)
        @test v.data == [2, 3, 4, 5, 6]

        push!(v, 1)
        @test v.data == [1, 2, 3, 4, 5, 6]
    end

    @testset "With ordering function" begin

        v = SortedVector([(5, "a"), (2, "b")], x->x[1])
        @test v.data == [(2, "b"), (5, "a")]

        push!(v, (3, "z")
        @test v.data == [(2, "b"), (3, "z"), (5, "a")]

        push!(v, (6, "z"), (4, "y"))
        @test v.data == [(2, "b"), (3, "z"), (4, "y"), (5, "a"), (6, "z")])

        push!(v, (1, "x"))
        @test v.data == [(1, "x"), (2, "b"), (3, "z"), (4, "y"), (5, "a"), (6, "z")])

    end

end
