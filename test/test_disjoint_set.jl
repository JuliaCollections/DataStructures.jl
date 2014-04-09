# Test disjoint set

using DataStructures
using Base.Test

s = DisjointSets{Int}(1:10)

@test length(s) == 10
@test num_groups(s) == 10

r = [find_root(s, i) for i in 1 : 10]
@test isa(r, Vector{Int})
@test isequal(r, [1:10])

for i = 1 : 5
    x = 2 * i - 1
    y = 2 * i
    union!(s, x, y)
end

@test length(s) == 10
@test num_groups(s) == 5

r0 = [1, 1, 3, 3, 5, 5, 7, 7, 9, 9]
r = [find_root(s, i) for i in 1 : 10]
@test isa(r, Vector{Int})
@test isequal(r, r0)

union!(s, 1, 4)
union!(s, 3, 5)
union!(s, 7, 9)

@test length(s) == 10
@test num_groups(s) == 2

r0 = [1, 1, 1, 1, 1, 1, 7, 7, 7, 7]
r = [find_root(s, i) for i in 1 : 10]
@test isa(r, Vector{Int})
@test isequal(r, r0)

add_singleton!(s, 17)

@test length(s) == 11
@test num_groups(s) == 3

r0 = [1, 1, 1, 1, 1, 1, 7, 7, 7, 7, 11]
r = [find_root(s, i) for i in [1 : 10, 17] ]
@test isa(r, Vector{Int})
@test isequal(r, r0)


