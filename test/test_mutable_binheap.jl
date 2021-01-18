# Test of binary heaps

# auxiliary functions

function heap_values(h::MutableBinaryHeap{VT,O}) where {VT,O}
    n = length(h)
    nodes = h.nodes
    @assert length(nodes) == n
    vs = Vector{VT}(undef, n)
    for i = 1 : n
        vs[i] = nodes[i].value
    end
    vs
end

function list_values(h::MutableBinaryHeap{VT,O}) where {VT,O}
    n = length(h)
    nodes = h.nodes
    nodemap = h.node_map
    vs = Vector{VT}()
    for i = 1 : length(nodemap)
        id = nodemap[i]
        if id > 0
            push!(vs, nodes[id].value)
        end
    end
    vs
end

function verify_heap(h::MutableBinaryHeap{VT,O}) where {VT,O}
    ord = h.ordering
    nodes = h.nodes
    n = length(h)
    m = div(n,2)
    for i = 1 : m
        v = nodes[i].value
        lc = i * 2
        if lc <= n
            if Base.lt(ord, nodes[lc].value, v)
                return false
            end
        end
        rc = lc + 1
        if rc <= n
            if Base.lt(ord, nodes[rc].value, v)
                return false
            end
        end
    end
    return true
end

@testset "MutableBinheap" begin

    vs = [4, 1, 3, 2, 16, 9, 10, 14, 8, 7]
    vs2 = collect(enumerate(vs))
    ordering = Base.Order.By(last)

    @testset "construct heap" begin
        MutableBinaryHeap{Int, Base.ForwardOrdering}()
        MutableBinaryHeap{Int, Base.ForwardOrdering}(vs)

        MutableBinaryHeap{Int, Base.ReverseOrdering}()
        MutableBinaryHeap{Int, Base.ReverseOrdering}(vs)

        MutableBinaryMinHeap{Int}()
        MutableBinaryMinHeap{Int}(vs)
        MutableBinaryMinHeap(vs)

        MutableBinaryMaxHeap{Int}()
        MutableBinaryMaxHeap{Int}(vs)
        MutableBinaryMaxHeap(vs)

        MutableBinaryHeap{eltype(vs2)}(ordering)
        MutableBinaryHeap{eltype(vs2)}(ordering, vs2)
        MutableBinaryHeap(ordering, vs2)

        @test true
    end

    @testset "Type Aliases" begin
        # https://github.com/JuliaCollections/DataStructures.jl/issues/686
        @test MutableBinaryMaxHeap{Int}() isa MutableBinaryMaxHeap{Int}
        @test MutableBinaryMinHeap{Int}() isa MutableBinaryMinHeap{Int}
    end

    @testset "basic tests" begin
        h = MutableBinaryMinHeap{Int}()

        @test length(h) == 0
        @test isempty(h)
        @test eltype(h) == Int
        @test eltype(typeof(h)) == Int
    end

    @testset "make mutable binary minheap" begin
        h = MutableBinaryMinHeap(vs)

        @test length(h) == 10
        @test !isempty(h)
        @test first(h) == 1
        @test isequal(list_values(h), vs)
        @test isequal(heap_values(h), [1, 2, 3, 4, 7, 9, 10, 14, 8, 16])
        @test sizehint!(h, 100) === h
    end

    @testset "make mutable binary maxheap" begin
        h = MutableBinaryMaxHeap(vs)

        @test length(h) == 10
        @test !isempty(h)
        @test first(h) == 16
        @test isequal(list_values(h), vs)
        @test isequal(heap_values(h), [16, 14, 10, 8, 7, 3, 9, 1, 4, 2])
        @test sizehint!(h, 100) === h
    end

    @testset "make mutable binary custom ordering heap" begin
        h = MutableBinaryHeap(ordering, vs2)

        @test length(h) == 10
        @test !isempty(h)
        @test first(h) == (2, 1)
        @test isequal(list_values(h), vs2)
        @test isequal(heap_values(h), [(2, 1), (4, 2), (3, 3), (1, 4), (10, 7), (6, 9), (7, 10), (8, 14), (9, 8), (5, 16)])
        @test sizehint!(h, 100) === h
    end

    @testset "hmin / push! / pop!" begin
        hmin = MutableBinaryMinHeap{Int}()
        @test length(hmin) == 0
        @test isempty(hmin)

        # test push!
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
            ia = push!(hmin, vs[i])
            @test ia == i
            @test length(hmin) == i
            @test !isempty(hmin)
            @test isequal(list_values(hmin), vs[1:i])
            @test isequal(heap_values(hmin), ss[i])
        end

        # test pop!
        @test isequal(extract_all!(hmin), [1, 2, 3, 4, 7, 8, 9, 10, 14, 16])
        @test isempty(hmin)
    end

    @testset "hmax / push! / pop!" begin
        hmax = MutableBinaryMaxHeap{Int}()
        @test length(hmax) == 0
        @test isempty(hmax)

        # test push!
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
            ia = push!(hmax, vs[i])
            @test ia == i
            @test length(hmax) == i
            @test !isempty(hmax)
            @test isequal(list_values(hmax), vs[1:i])
            @test isequal(heap_values(hmax), ss[i])
        end

        # test pop!
        @test isequal(extract_all!(hmax), [16, 14, 10, 9, 8, 7, 4, 3, 2, 1])
        @test isempty(hmax)
    end

    @testset "Custom ordering push! / pop!" begin
        heap = MutableBinaryHeap{Tuple{Int,Int}}(ordering)
        @test length(heap) == 0
        @test isempty(heap)

        # test push!
        ss = Any[
            [(1, 4)],
            [(2, 1), (1, 4)],
            [(2, 1), (1, 4), (3, 3)],
            [(2, 1), (4, 2), (3, 3), (1, 4)],
            [(2, 1), (4, 2), (3, 3), (1, 4), (5, 16)],
            [(2, 1), (4, 2), (3, 3), (1, 4), (5, 16), (6, 9)],
            [(2, 1), (4, 2), (3, 3), (1, 4), (5, 16), (6, 9), (7, 10)],
            [(2, 1), (4, 2), (3, 3), (1, 4), (5, 16), (6, 9), (7, 10), (8, 14)],
            [(2, 1), (4, 2), (3, 3), (1, 4), (5, 16), (6, 9), (7, 10), (8, 14), (9, 8)],
            [(2, 1), (4, 2), (3, 3), (1, 4), (10, 7), (6, 9), (7, 10), (8, 14), (9, 8), (5, 16)]]
        for i = 1 : length(vs2)
            ia = push!(heap, vs2[i])
            @test ia == i
            @test length(heap) == i
            @test !isempty(heap)
            @test isequal(list_values(heap), vs2[1:i])
            @test isequal(heap_values(heap), ss[i])
        end

        # test pop!
        @test isequal(extract_all!(heap), sort(vs2, order=ordering))
        @test isempty(heap)
    end

    @testset "hybrid push! and pop!" begin
        h = MutableBinaryMinHeap{Int}()

        push!(h, 5)
        push!(h, 10)
        @test isequal(heap_values(h), [5, 10])
        @test isequal(list_values(h), [5, 10])

        @test pop!(h) == 5
        @test isequal(heap_values(h), [10])
        @test isequal(list_values(h), [10])

        push!(h, 7)
        push!(h, 2)
        @test isequal(heap_values(h), [2, 10, 7])
        @test isequal(list_values(h), [10, 7, 2])

        @test pop!(h) == 2
        @test isequal(heap_values(h), [7, 10])
        @test isequal(list_values(h), [10, 7])

    end

    @testset "test delete!" begin
        vs=[1,2,4,6,3]
        h = MutableBinaryMinHeap(vs)

        @test isequal(heap_values(delete!(h,1)), [2, 3, 4, 6])
        @test isequal(heap_values(delete!(h,5)), [2, 6, 4])
        @test_throws BoundsError delete!(h,10)
        @test_throws BoundsError delete!(h,0)
        @test_throws BoundsError delete!(h,-5)
        @test pop!(h) == 2
        @test pop!(h) == 4
        push!(h,2)
        @test pop!(h) == 2
        @test pop!(h) == 6
        @test isempty(h)
        #bubble_up test
        vv = [1, 9, 22, 17, 11, 33, 27, 21, 19]
        hp = MutableBinaryMinHeap(vv)
        delete!(hp, 6)
        @test isequal(extract_all!(hp), [1, 9, 11, 17, 19, 21, 22, 27])
    end

    @testset "test delete! at end" begin
        h = MutableBinaryMinHeap{Int}()
        push!(h, 1)
        handle = push!(h, 2)
        delete!(h, handle)
        @test isequal(heap_values(h), [1])
    end

    @testset "test delete! at end of 3-element heap" begin
        h = MutableBinaryMinHeap{Int}()
        push!(h, 1)
        push!(h, 2)
        handle = push!(h, 3)
        delete!(h, handle)
        @test isequal(heap_values(h), [1, 2])
    end

    @testset "test update! and top_with_handle" begin
        for (hf,m) = [(MutableBinaryMinHeap,-2.0), (MutableBinaryMaxHeap,2.0)]
            xs = rand(100)
            h = hf(xs)
            @test length(h) == 100
            @test verify_heap(h)

            for t = 1:1000
                i = rand(1:100)
                v = rand()
                xs[i] = v
                update!(h, i, v)
                @test length(h) == 100
                @test verify_heap(h)
                @test isequal(list_values(h), xs)

                v, i = top_with_handle(h)
                update!(h, i, m)
                xs[i] = m
                @test length(h) == 100
                @test verify_heap(h)
                @test isequal(list_values(h), xs)
                @test top_with_handle(h) == (m, i)

                update!(h, i, -m)
                xs[i] = -m
                @test length(h) == 100
                @test verify_heap(h)
                @test isequal(list_values(h), xs)
                @test top_with_handle(h)[2] ≠ i

                update!(h, i, v)
                xs[i] = v
                @test length(h) == 100
                @test verify_heap(h)
                @test isequal(list_values(h), xs)
                @test top_with_handle(h) == (v, i)

                i = rand(1:100)
                v = rand()
                h[i] = v
                xs[i] = v
                @test length(h) == 100
                @test verify_heap(h)
                @test isequal(list_values(h), xs)
                @test v == h[i]
            end
        end
    end

    @testset "test push! and update! conversion" begin # issue 399
        h = MutableBinaryMinHeap{Float64}()
        push!(h, 3.0)
        push!(h, 5)
        push!(h, Rational(4, 8))
        push!(h, Complex(10.1, 0.0))
        @test isequal(heap_values(h), [0.5, 5.0, 3.0, 10.1])

        update!(h, 2, 20)
        @test isequal(heap_values(h), [0.5, 10.1, 3.0, 20.0])
    end
end # @testset MutableBinheap
