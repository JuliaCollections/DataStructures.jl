@testset "MutableLinkedList" begin

    @testset "empty list" begin
        l1 = MutableLinkedList{Int}()
        @test isempty(l1)
        @test length(l1) == 0
        @test collect(l1) == Int[]
        @test eltype(l1) == Int
        @test_throws ArgumentError pop!(l1)
        @test_throws ArgumentError popfirst!(l1)
    end

    @testset "core functionality" begin
        n = 10

        @testset "push back / pop back" begin
            l = MutableLinkedList{Int}()

            @testset "push back" begin
                for i = 1:n
                    push!(l, i)
                    @test last(l) == i
                    @test length(l) == i
                    @test isempty(l) == false
                    for (j, k) in enumerate(l)
                        @test j == k
                    end
                    cl = collect(l)
                    @test isa(cl, Vector{Int})
                    @test cl == collect(1:i)
                end
            end

            @testset "pop back" begin
                for i = 1:n
                    x = pop!(l)
                    @test length(l) == n - i
                    @test isempty(l) == (i == n)
                    @test x == n - i + 1
                    cl = collect(l)
                    @test cl == collect(1:n-i)
                end
            end
        end

        @testset "push front / pop front" begin
            l = MutableLinkedList{Int}()

            @testset "push front" begin
                for i = 1:n
                    pushfirst!(l, i)
                    @test first(l) == i
                    @test length(l) == i
                    @test isempty(l) == false
                    cl = collect(l)
                    @test isa(cl, Vector{Int})
                    @test cl == collect(i:-1:1)
                end
            end

            @testset "pop front" begin
                for i = 1:n
                    x = popfirst!(l)
                    @test length(l) == n - i
                    @test isempty(l) == (i == n)
                    @test x == n - i + 1
                    cl = collect(l)
                    @test cl == collect(n-i:-1:1)
                end
            end

        end

        @testset "append / delete / copy / reverse" begin
            for i = 1:n
                l = MutableLinkedList{Int}(1:n...)

                @testset "append" begin
                    l2 = MutableLinkedList{Int}(n+1:2n...)
                    append!(l, l2)
                    @test l == MutableLinkedList{Int}(1:2n...)
                end

                @testset "delete" begin
                    delete!(l, n+1:2n)
                    @test l == MutableLinkedList{Int}(1:n...)
                    for i = n:-1:1
                        delete!(l, i)
                    end
                    @test l == MutableLinkedList{Int}()
                    l = MutableLinkedList{Int}(1:n...)
                    @test_throws BoundsError delete!(l, n-1:2n)
                    @test_throws BoundsError delete!(l, 2n)
                end

                @testset "copy" begin
                    l2 = copy(l)
                    @test l == l2
                end

                @testset "reverse" begin
                    l2 = MutableLinkedList{Int}(n:-1:1...)
                    @test l == reverse(l2)
                end
            end
        end

        @testset "map / filter" begin
            for i = 1:n
                @testset "map" begin
                    l = MutableLinkedList{Int}(1:n...)
                    @test map(x -> 2x, l) == MutableLinkedList{Int}(2:2:2n...)
                end

                @testset "filter" begin
                    l = MutableLinkedList{Int}(1:n...)
                    @test filter(x -> x % 2 == 0, l) == MutableLinkedList{Int}(2:2:n...)
                end
            end
        end
    end

    @testset "random operations" begin
        l = MutableLinkedList{Int}()
        r = Int[]
        m = 100

        for k = 1 : m
            la = rand(1:20)
            x = rand(1:1000, la)

            for i = 1 : la
                if rand(Bool)
                    push!(r, x[i])
                    push!(l, x[i])
                else
                    pushfirst!(r, x[i])
                    pushfirst!(l, x[i])
                end
            end

            @test length(l) == length(r)
            @test collect(l) == r

            lr = rand(1:length(r))
            for i = 1 : lr
                if rand(Bool)
                    pop!(r)
                    pop!(l)
                else
                    popfirst!(r)
                    popfirst!(l)
                end
            end

            @test length(l) == length(r)
            @test collect(l) == r
        end
    end
end
