# Test disjoint set

s = IntDisjointSets(10)

@test length(s) == 10
@test num_groups(s) == 10

for i = 1:10
    @test find_root(s, i) == i
end
@test_throws BoundsError find_root(s, 11)

@test !in_same_set(s, 2, 3)

union!(s, 2, 3)
@test num_groups(s) == 9
@test in_same_set(s, 2, 3)
@test find_root(s, 3) == 2
union!(s, 3, 2)
@test num_groups(s) == 9
@test in_same_set(s, 2, 3)
@test find_root(s, 3) == 2

# We cannot support arbitrary indexing and still use @inbounds with IntDisjointSets
# (and it's not useful anyway)
@test_throws MethodError push!(s, 22)

@test push!(s) == 11
@test num_groups(s) == 10

@test union!(s, 8, 7) == 8
@test union!(s, 5, 6) == 5
@test union!(s, 8, 5) == 8
@test num_groups(s) == 7
@test find_root(s, 6) == 8
union!(s, 2, 6)
@test find_root(s, 2) == 8
root1 = find_root(s, 6)
root2 = find_root(s, 2)
@test root_union!(s, root1, root2) == 8
@test union!(s, 5, 6) == 8

s = DisjointSets{Int}(1:10)

@test length(s) == 10
@test num_groups(s) == 10

r = [find_root(s, i) for i in 1 : 10]
@test isa(r, Vector{Int})
@test isequal(r, collect(1:10))

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

@test union!(s, 1, 4) == 1
@test union!(s, 3, 5) == 1
@test union!(s, 7, 9) == 7

@test length(s) == 10
@test num_groups(s) == 2

r0 = [1, 1, 1, 1, 1, 1, 7, 7, 7, 7]
r = [find_root(s, i) for i in 1 : 10]
@test isa(r, Vector{Int})
@test isequal(r, r0)

push!(s, 17)

@test length(s) == 11
@test num_groups(s) == 3

r0 = [1, 1, 1, 1, 1, 1, 7, 7, 7, 7, 11]
r = [find_root(s, i) for i in [1 : 10; 17] ]
@test isa(r, Vector{Int})
@test isequal(r, r0)

root1 = find_root(s, 7)
root2 = find_root(s, 3)
@test root_union!(s, root1, root2) == 7
@test find_root(s, 7) == 7
@test find_root(s, 3) == 7
