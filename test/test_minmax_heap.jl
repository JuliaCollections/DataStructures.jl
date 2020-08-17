# tests for min-max heaps
using DataStructures: _make_binary_minmax_heap, is_minmax_heap, children_and_grandchildren
using Base.Order: Forward, Reverse

@testset "Binary MinMax Heaps" begin

    @testset "construct heap" begin
        vs = [10, 4, 6, 1, 16, 2, 20, 17, 13, 5]

        BinaryMinMaxHeap{Int}()
        BinaryMinMaxHeap{Int}(vs)
        BinaryMinMaxHeap(vs)

        @test true
    end

    @testset "is_minmax_heap tests" begin
        mmheap = [0, 10, 9, 2, 3, 4, 5]
        @test is_minmax_heap(mmheap)
        @test is_minmax_heap([])
        @test is_minmax_heap([rand()])
    end

    @testset "basic tests" begin
        h = BinaryMinMaxHeap{Int}()

        @test length(h) == 0
        @test isempty(h)
        @test eltype(h) == Int
        @test eltype(typeof(h)) == Int
        @test sizehint!(h, 100) === h
    end

    @testset "make heap tests" begin
        vs = [10, 4, 6, 1, 16, 2, 20, 17, 13, 5]

        @testset "make from array tests" begin
            h = BinaryMinMaxHeap(vs)
            @test length(h) == 10
            @test !isempty(h)
            @test first(h) == minimum(h) == 1
            @test maximum(h) == 20
            @test is_minmax_heap(h.valtree)
        end

        @testset "make from random arrays tests" begin
            for i = 1:20
                A = rand(50)
                vtree = _make_binary_minmax_heap(A)
                @test is_minmax_heap(vtree)
            end
        end

        @testset "push! tests" begin
            h = BinaryMinMaxHeap{Int}()

            @test length(h) == 0
            @test isempty(h)

            push!(h, 1)
            @test first(h) == 1
            push!(h, 2)
            @test is_minmax_heap(h.valtree)
            push!(h, 10)
            @test is_minmax_heap(h.valtree)
            push!(h, rand(Int))
            @test is_minmax_heap(h.valtree)
            for i = 1:5
                A = rand(20)
                hs = BinaryMinMaxHeap(A)
                for j = 1:4
                    push!(hs, rand())
                    @test is_minmax_heap(hs.valtree)
                end
            end
        end
    end

    @testset "pop! tests" begin
        @testset "popmin! tests" begin
            h = BinaryMinMaxHeap([1])
            @test popmin!(h) == 1
            @test length(h) == 0
            @test isempty(h)
            h = BinaryMinMaxHeap([1, 3, 2])
            @test popmin!(h) == 1
            @test length(h) == 2
            @test is_minmax_heap(h.valtree)
            @test minimum(h) == 2
            for i = 1:20
                A = rand(50)
                h = BinaryMinMaxHeap(A)
                minval = minimum(A)
                @test popmin!(h) == minval
                @test length(h) == 49
                @test is_minmax_heap(h.valtree)
            end
        end
        @testset "popmax! tests" begin
            h = BinaryMinMaxHeap([1])
            @test popmax!(h) == 1
            @test length(h) == 0
            @test isempty(h)
            h = BinaryMinMaxHeap([1, 2, 3])
            @test popmax!(h) == 3
            @test length(h) == 2
            @test is_minmax_heap(h.valtree)
            @test maximum(h) == 2
            h = BinaryMinMaxHeap([1, 3, 2])
            @test popmax!(h) == 3
            @test length(h) == 2
            @test is_minmax_heap(h.valtree)
            @test maximum(h) == 2
        end
    end

    @testset "empty!" begin
        h = BinaryMinMaxHeap([1, 4, 3, 10, 2])
        ret = empty!(h)
        @test ret === h
        @test length(ret) == 0
        @test isempty(ret)
    end

    @testset "popall!" begin
        @testset "popmin! tests" begin
            A = rand(Int, 50)
            sorted_A = sort(A)
            h = BinaryMinMaxHeap(A)
            @test popall!(h) == sorted_A
            @test isempty(h)
            @test length(h) == 0

            h = BinaryMinMaxHeap(A)
            @test popmin!(h, 10) == sorted_A[1:10]
            @test !isempty(h)
            @test length(h) == 40
        end
        @testset "popmax! tests" begin
            A = rand(Int, 50)
            sorted_A = sort(A, order=Reverse)
            h = BinaryMinMaxHeap(A)
            @test popall!(h, Reverse) == sorted_A
            @test length(h) == 0
            @test isempty(h)

            h = BinaryMinMaxHeap(A)
            @test popmax!(h, 10) == sorted_A[1:10]
            @test length(h) == 40
            @test !isempty(h)
        end
    end

    @testset "type conversion" begin
        h = BinaryMinMaxHeap{Float64}()
        push!(h, 3.)
        push!(h, 5)
        push!(h, Rational(4, 8))
        push!(h, Complex(10.1, 0.0))

        @test h.valtree == [0.5, 10.1, 3.0, 5.0]
    end

    @testset "children_and_grandchildren tests" begin
        @test children_and_grandchildren(1, 1) == Int[]
        @test children_and_grandchildren(2, 1) == [2]
        @test children_and_grandchildren(3, 1) == [2, 3]
        @test children_and_grandchildren(7, 1) == [2, 4, 5, 3, 6, 7]
        @test children_and_grandchildren(10, 2) == [4, 8, 9, 5, 10]
    end

    @testset "throw errors tests" begin
        h = BinaryMinMaxHeap{Int}()
        @test_throws ArgumentError pop!(h)
        @test_throws ArgumentError popmin!(h)
        @test_throws ArgumentError popmax!(h)

        @test_throws ArgumentError minimum(h)
        @test_throws ArgumentError maximum(h)

    end
end
