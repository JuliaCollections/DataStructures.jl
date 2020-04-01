# Test of binary heaps

# auxiliary functions
using DataStructures, Test

function heap_values(h::MutableBinomialHeap{VT}) where VT
    n = length(h)
    vs = Vector{VT}(undef, n)
    k = 1
    val::Union{Nothing,MutableBinomialHeapNode{VT}} = nothing
    for i = 1:h.cumm_nodecount
        val = nothing
        try
            val = find_node(h, i)
            vs[k] = val.data
            k += 1
        catch _    
            continue
        end
    end
    vs
end

function check_tree(node::Union{MutableBinomialHeapNode{T},Nothing}) where T
    if node === nothing 
        return true
    end
    if node.parent !== nothing && node.data < node.parent.data 
        return false
    end
    return check_tree(node.child)
    return check_tree(node.sibling)
end

function verify_heap(h::MutableBinomialHeap{T}) where {T}
    n = length(h.rootList)
    if n > (floor(log2(length(h))) + 1)
        return false
    end
    a::Vector{Int} = []
    for i = 1:n
        if !check_tree(h.rootList[i])
            return false
        end
        push!(a, h.rootList[i].degree)
    end
    len = length(a)
    unique!(a)
    if len > length(a)
        return false
    end
    return true
end

@testset "MutableBinomialheap" begin

    vs = [4, 1, 3, 2, 16, 9, 10, 14, 8, 7]

    @testset "basic tests" begin
        h = MutableBinomialHeap{Int}()

        @test length(h) == 0
        @test isempty(h)
        @test eltype(h) == Int
        @test eltype(typeof(h)) == Int
    end

    @testset "make mutable binomial heap" begin
        h = MutableBinomialHeap(vs)

        @test length(h) == 10
        @test !isempty(h)
        @test top(h) == 1
        @test isequal(heap_values(h), vs)
        @test sizehint!(h, 100) === h
    end

    @testset "setindex! and getindex" begin
        h = MutableBinomialHeap(vs)

        @test getindex(h, 1) == 4
        @test getindex(h, 10) == 7
        setindex!(h, 5, 1)
        @test getindex(h, 1) == 5
    end

    @testset "h / push! / pop!" begin
        h = MutableBinomialHeap{Int}()
        @test length(h) == 0
        @test isempty(h)

        # test push!
        ss = Any[
            [4],
            [4, 1],
            [4, 1, 3],
            [4, 1, 3, 2],
            [4, 1, 3, 2, 16],
            [4, 1, 3, 2, 16, 9],
            [4, 1, 3, 2, 16, 9,10],
            [4, 1, 3, 2, 16, 9, 10, 14],
            [4, 1, 3, 2, 16, 9, 10, 14, 8],
            [4, 1, 3, 2, 16, 9, 10, 14, 8,7]]
        for i = 1:length(vs)
            ia = push!(h, vs[i])
            @test ia == i
            @test length(h) == i
            @test !isempty(h)
            @test isequal(heap_values(h), ss[i])
        end

        @test isequal(extract_all!(h), [1, 2, 3, 4, 7, 8, 9, 10, 14, 16])
        @test isempty(h)
    end

    @testset "hybrid push! and pop!" begin
        h = MutableBinomialHeap{Int}()

        push!(h, 5)
        push!(h, 10)
        @test isequal(heap_values(h), [5, 10])

        @test pop!(h) == 5
        @test isequal(heap_values(h), [10])

        push!(h, 7)
        push!(h, 2)
        @test isequal(heap_values(h), [10, 7, 2])

        @test pop!(h) == 2
        @test isequal(heap_values(h), [10, 7])

    end

    @testset "test delete!" begin
        vs = [1,2,4,6,3]
        h = MutableBinomialHeap(vs)

        @test isequal(heap_values(delete!(h, 1)), [2, 4, 6, 3])
        @test isequal(heap_values(delete!(h, 5)), [2, 4, 6])
        @test_throws HeapBoundsError delete!(h, 10)
        @test_throws HeapBoundsError delete!(h, 0)
        @test_throws HeapBoundsError delete!(h, -5)
        @test pop!(h) == 2
        @test pop!(h) == 4
        push!(h, 2)
        @test pop!(h) == 2
        @test pop!(h) == 6
        @test isempty(h)
        vv = [1, 9, 22, 17, 11, 33, 27, 21, 19]
        hp = MutableBinomialHeap(vv)
        delete!(hp, 6)
        @test isequal(extract_all!(hp), [1, 9, 11, 17, 19, 21, 22, 27])
    end

    @testset "test update! and top_with_handle" begin
        xs = rand(100)
        h = MutableBinomialHeap(xs)
        @test length(h) == 100
        @test verify_heap(h)

        for t = 1:1000
            i = rand(1:100)
            v = rand()
            update!(h, i, v)
            xs[i] = v
            @test length(h) == 100
            @test verify_heap(h)

            m = -2
            v, handle = top_with_handle(h)
            update!(h, handle, m)
            xs[i] = m
            @test length(h) == 100
            @test verify_heap(h)
            @test top_with_handle(h)[1] == m
            @test top_with_handle(h)[2] == handle 

            update!(h, handle, -m)
            xs[i] = -m
            @test length(h) == 100
            @test verify_heap(h)
            @test top_with_handle(h)[2] ≠ handle

            update!(h, handle, v)
            xs[i] = v
            @test length(h) == 100
            @test verify_heap(h)
            @test top_with_handle(h) == (v, handle)
        end
    end

    @testset "test push! and update! conversion" begin 
        h = MutableBinomialHeap{Float64}()
        push!(h, 3.0)
        push!(h, 5)
        push!(h, Rational(4, 8))
        push!(h, Complex(10.1, 0.0))
        @test isequal(heap_values(h), [3.0, 5.0, 0.5, 10.1])

        update!(h, 2, 20)
        @test isequal(heap_values(h), [ 3.0, 20.0, 0.5, 10.1])
    end

    @testset "test union!" begin 
        vs1 = [1,3,4,8]
        vs2 = [5,6,7,2]
        h1 = MutableBinomialHeap{Int}(vs1)
        h2 = MutableBinomialHeap{Int}(vs2)
        _union!(h1, h2)
        @test verify_heap(h1)
        @test isequal(heap_values(h1), [1,3,4,8,5,6,7,2])
    end

end # @testset BinaryHeap
