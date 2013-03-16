# Test of binary heaps

using DataStructures
using Test

# auxiliary functions

function heap_values{VT,Comp}(h::BinaryHeap{VT,Comp})
    n = length(h)
    nodes = h.nodes
    @assert length(nodes) == n
    vs = Array(VT, n)
    for i = 1 : n
        vs[i] = nodes[i].value
    end
    vs
end

function list_values{VT,Comp}(h::BinaryHeap{VT,Comp})
    n = length(h)
    nodes = h.nodes
    nodemap = h.node_map
    vs = Array(VT, 0)
    for i = 1 : length(nodemap)
        id = nodemap[i]
        if id > 0
            push!(vs, nodes[id].value)
        end
    end
    vs
end

function verify_heap{VT,Comp}(h::BinaryHeap{VT,Comp})
    comp = h.comparer
    nodes = h.nodes
    n = length(h)
    m = n / 2
    for i = 1 : m
        v = nodes[i].value
        lc = i * 2
        if lc <= n
            if compare(comp, nodes[lc].value, v)
                return false
            end            
        end
        rc = lc + 1
        if rc <= n
            if compare(comp, nodes[rc].value, v)
                return false
            end
        end
    end
    return true
end



# test make heap

vs = [4, 1, 3, 2, 16, 9, 10, 14, 8, 7]
h = binary_minheap(vs)

@test length(h) == 10
@test !isempty(h)
@test top(h) == 1
@test isequal(list_values(h), vs)
@test isequal(heap_values(h), [1, 2, 3, 4, 7, 9, 10, 14, 8, 16])


h = binary_maxheap(vs)

@test length(h) == 10
@test !isempty(h)
@test top(h) == 16
@test isequal(list_values(h), vs)
@test isequal(heap_values(h), [16, 14, 10, 8, 7, 3, 9, 1, 4, 2])

# test push!

hmin = binary_minheap(Int)
@test length(hmin) == 0
@test isempty(hmin)

ss = {
    [4], 
    [1, 4],
    [1, 4, 3],
    [1, 2, 3, 4],
    [1, 2, 3, 4, 16],
    [1, 2, 3, 4, 16, 9],
    [1, 2, 3, 4, 16, 9, 10],
    [1, 2, 3, 4, 16, 9, 10, 14],
    [1, 2, 3, 4, 16, 9, 10, 14, 8],
    [1, 2, 3, 4, 7, 9, 10, 14, 8, 16]}

for i = 1 : length(vs)
    ia = push!(hmin, vs[i])
    @test ia == i
    @test length(hmin) == i
    @test !isempty(hmin)
    @test isequal(list_values(hmin), vs[1:i])
    @test isequal(heap_values(hmin), ss[i])
end

hmax = binary_maxheap(Int)
@test length(hmax) == 0
@test isempty(hmax)

ss = {
    [4],
    [4, 1],
    [4, 1, 3],
    [4, 2, 3, 1],
    [16, 4, 3, 1, 2],
    [16, 4, 9, 1, 2, 3],
    [16, 4, 10, 1, 2, 3, 9],
    [16, 14, 10, 4, 2, 3, 9, 1],
    [16, 14, 10, 8, 2, 3, 9, 1, 4],
    [16, 14, 10, 8, 7, 3, 9, 1, 4, 2]}

for i = 1 : length(vs)
    ia = push!(hmax, vs[i])
    @test ia == i
    @test length(hmax) == i
    @test !isempty(hmax)
    @test isequal(list_values(hmax), vs[1:i])
    @test isequal(heap_values(hmax), ss[i])
end

# test pop!

@test isequal(extract_all!(hmin), [1, 2, 3, 4, 7, 8, 9, 10, 14, 16])
@test isempty(hmin)

@test isequal(extract_all!(hmax), [16, 14, 10, 9, 8, 7, 4, 3, 2, 1])
@test isempty(hmax)

# test hybrid add! and pop!

h = binary_minheap(Int)

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


# test update!

xs = rand(100)
hmin = binary_minheap(xs)
hmax = binary_maxheap(xs)

@test length(hmin) == 100
@test length(hmax) == 100
@test verify_heap(hmin)
@test verify_heap(hmax)

for t = 1 : 1000    
    i = rand(1:100)
    v = rand()
    xs[i] = v
    update!(hmin, i, v)
    update!(hmax, i, v)
    @test length(hmin) == 100
    @test length(hmax) == 100
    @test verify_heap(hmin)
    @test verify_heap(hmax)
    @test isequal(list_values(hmin), xs)
    @test isequal(list_values(hmax), xs)
end

