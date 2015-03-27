# Test of binary heaps

using DataStructures
using Base.Test

# test make heap

vs = [4, 1, 3, 2, 16, 9, 10, 14, 8, 7]
h = binary_minheap(vs)

@test length(h) == 10
@test !isempty(h)
@test top(h) == 1
@test isequal(h.valtree, [1, 2, 3, 4, 7, 9, 10, 14, 8, 16])


h = binary_maxheap(vs)

@test length(h) == 10
@test !isempty(h)
@test top(h) == 16
@test isequal(h.valtree, [16, 14, 10, 8, 7, 3, 9, 1, 4, 2])

# test push!

hmin = binary_minheap(Int)
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

hmax = binary_maxheap(Int)
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

# test pop!

@test isequal(extract_all!(hmin), [1, 2, 3, 4, 7, 8, 9, 10, 14, 16])
@test isempty(hmin)

@test isequal(extract_all!(hmax), [16, 14, 10, 9, 8, 7, 4, 3, 2, 1])
@test isempty(hmax)

# test hybrid push! and pop!

h = binary_minheap(Int)

push!(h, 5)
push!(h, 10)
@test isequal(h.valtree, [5, 10])

@test pop!(h) == 5
@test isequal(h.valtree, [10])

push!(h, 7)
push!(h, 2)
@test isequal(h.valtree, [2, 10, 7])

@test pop!(h) == 2
@test isequal(h.valtree, [7, 10])

# Tests for nlargest and nsmallest
ss = [100,103,-12,-109,67,4,65,-52,-97,-32,-24,114,-128,
      102,-56,-17,-41,25,-30,-84,26,-84,48,49,-5,-38,28,
      114,-54,96,-55,67,74,127,-61,124,11,-7,93,-51,110,
      -106,-84,-90,-18,-12,-116,21,115,50]
for n = -1:length(ss) + 1
    @test sort(ss, lt = >)[1:min(n, end)] == nlargest(n, ss)
    @test sort(ss, lt = <)[1:min(n, end)] == nsmallest(n, ss)
end
