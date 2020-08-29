# Test of binary heaps

@testset "BinaryHeaps" begin

    @testset "make heap" begin
        vs = [4, 1, 3, 2, 16, 9, 10, 14, 8, 7]

        @testset "construct heap" begin
            BinaryHeap{Int, Base.ForwardOrdering}()
            BinaryHeap{Int, Base.ForwardOrdering}(vs)

            BinaryHeap{Int, Base.ReverseOrdering}()
            BinaryHeap{Int, Base.ReverseOrdering}(vs)

            BinaryMinHeap{Int}()
            BinaryMinHeap{Int}(vs)
            BinaryMinHeap(vs)

            BinaryMaxHeap{Int}()
            BinaryMaxHeap{Int}(vs)
            BinaryMaxHeap(vs)

            @test true
        end

        @testset "implicit conversion" begin
            BinaryHeap{Float64, Base.ForwardOrdering}(vs)
            BinaryMinHeap{Float64}(vs)
            BinaryMaxHeap{Float64}(vs)

            @test true
        end

        @testset "confirm heap" begin
            @test isheap([1, 2, 3, 4, 7, 9, 10, 14, 8, 16])
            @test isheap([16, 14, 10, 8, 7, 3, 9, 1, 4, 2], Base.Reverse)

            @test !isheap([16, 14, 10, 8, 7, 3, 9, 1, 4, 2])
            @test !isheap([1, 2, 3, 4, 7, 9, 10, 14, 8, 16], Base.Reverse)
            @test !isheap([15, 2, 3, 4, 7, 9, 10, 14, 8, 16])
            @test !isheap([15, 2, 3, 4, 7, 9, 10, 14, 8, 16], Base.Reverse)
        end

        @testset "make min heap" begin
            h = BinaryMinHeap(vs)

            @test length(h) == 10
            @test !isempty(h)
            @test first(h) == 1
            @test isheap([1, 2, 3, 4, 7, 9, 10, 14, 8, 16])
            @test sizehint!(h, 100) === h
        end

        @testset "make max heap" begin
            h = BinaryMaxHeap(vs)

            @test length(h) == 10
            @test !isempty(h)
            @test first(h) == 16
            @test isheap([16, 14, 10, 8, 7, 3, 9, 1, 4, 2], Base.Reverse)
            @test sizehint!(h, 100) === h
        end

        @testset "extract all" begin
            @test sort(vs) == extract_all!(BinaryMinHeap(vs))
            @test reverse(sort(vs)) == extract_all_rev!(BinaryMinHeap(vs))
        end

        @testset "push!" begin
            @testset "push! hmin" begin
                hmin = BinaryMinHeap{Int}()
                @test length(hmin) == 0
                @test isempty(hmin)

                ss = Any[
                    [4],
                    [1, 4],
                    [1, 4, 3],
                    [1, 2, 3, 4],
                    [1, 2, 3, 4, 16],
                    [1, 2, 3, 4, 16, 9],
                    [1, 2, 3, 4, 16, 9, 10],
                    [1, 2, 3, 4, 16, 9, 10, 14],
                    [1, 2, 3, 4, 16, 9, 10, 14, 8],
                    [1, 2, 3, 4, 7, 9, 10, 14, 8, 16]]

                for i = 1 : length(vs)
                    push!(hmin, vs[i])
                    @test length(hmin) == i
                    @test !isempty(hmin)
                    @test isequal(hmin.valtree, ss[i])
                end

                @testset "pop! hmin" begin
                    @test isequal(extract_all!(hmin), [1, 2, 3, 4, 7, 8, 9, 10, 14, 16])
                    @test isempty(hmin)
                end

            end

            @testset "push! hmax" begin
                hmax = BinaryMaxHeap{Int}()
                @test length(hmax) == 0
                @test isempty(hmax)

                ss = Any[
                    [4],
                    [4, 1],
                    [4, 1, 3],
                    [4, 2, 3, 1],
                    [16, 4, 3, 1, 2],
                    [16, 4, 9, 1, 2, 3],
                    [16, 4, 10, 1, 2, 3, 9],
                    [16, 14, 10, 4, 2, 3, 9, 1],
                    [16, 14, 10, 8, 2, 3, 9, 1, 4],
                    [16, 14, 10, 8, 7, 3, 9, 1, 4, 2]]

                for i = 1 : length(vs)
                    push!(hmax, vs[i])
                    @test length(hmax) == i
                    @test !isempty(hmax)
                    @test isequal(hmax.valtree, ss[i])
                end

                @testset "pop! hmax" begin
                    @test isequal(extract_all!(hmax), [16, 14, 10, 9, 8, 7, 4, 3, 2, 1])
                    @test isempty(hmax)
                end
            end
        end

    end

    @testset "hybrid push! and pop!" begin
        h = BinaryMinHeap{Int}()

        @testset "push1" begin
            push!(h, 5)
            push!(h, 10)
            @test isequal(h.valtree, [5, 10])
        end

        @testset "pop1" begin
            @test pop!(h) == 5
            @test isequal(h.valtree, [10])
        end

        @testset "push2" begin
            push!(h, 7)
            push!(h, 2)
            @test isequal(h.valtree, [2, 10, 7])
        end

        @testset "pop2" begin
            @test pop!(h) == 2
            @test isequal(h.valtree, [7, 10])
        end
    end

    @testset "nlargest and nsmallest" begin
        ss = [100,103,-12,-109,67,4,65,-52,-97,-32,-24,114,-128,
            102,-56,-17,-41,25,-30,-84,26,-84,48,49,-5,-38,28,
            114,-54,96,-55,67,74,127,-61,124,11,-7,93,-51,110,
            -106,-84,-90,-18,-12,-116,21,115,50]
        for n = -1:length(ss) + 1
            @test sort(ss, lt = >)[1:min(n, end)] == nlargest(n, ss)
            @test sort(ss, lt = <)[1:min(n, end)] == nsmallest(n, ss)
            @test nlargest(n, ss) == DataStructures.nextreme(DataStructures.FasterReverse(), n, ss)
            @test nsmallest(n, ss) == DataStructures.nextreme(DataStructures.FasterForward(), n, ss)
        end
    end

    @testset "push! type conversion" begin # issue 399
        h = BinaryMinHeap{Float64}()
        push!(h, 3.0)
        push!(h, 5)
        push!(h, Rational(4, 8))
        push!(h, Complex(10.1, 0.0))

        @test isequal(h.valtree, [0.5, 5.0, 3.0, 10.1])
    end
end # @testset BinaryHeap
