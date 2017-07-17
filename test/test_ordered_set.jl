using DataStructures
using Base.Test

# construction

@test isa(OrderedSet(), OrderedSet{Any})
@test isa(OrderedSet([1,2,3]), OrderedSet{Int})
@test isa(OrderedSet{Int}([3]), OrderedSet{Int})
data_in = (1, "banana", ())
s = OrderedSet(data_in)
data_out = collect(s)
@test isa(data_out, Array{Any,1})
@test tuple(data_out...) === data_in
@test tuple(data_in...) === tuple(s...)
@test length(data_out) == length(data_in)

# hash
s1 = OrderedSet{String}(["bar", "foo"])
s2 = OrderedSet{String}(["foo", "bar"])
s3 = OrderedSet{String}(["baz"])
@test hash(s1) != hash(s2)
@test hash(s1) != hash(s3)


# isequal
@test  isequal(OrderedSet(), OrderedSet())
@test !isequal(OrderedSet(), OrderedSet([1]))
@test  isequal(OrderedSet{Any}(Any[1,2]), OrderedSet{Int}([1,2]))
@test !isequal(OrderedSet{Any}(Any[1,2]), OrderedSet{Int}([1,2,3]))

@test  isequal(OrderedSet{Int}(), OrderedSet{AbstractString}())
@test !isequal(OrderedSet{Int}(), OrderedSet{AbstractString}([""]))
@test !isequal(OrderedSet{AbstractString}(), OrderedSet{Int}([0]))
@test !isequal(OrderedSet{Int}([1]), OrderedSet{AbstractString}())
@test  isequal(OrderedSet{Any}([1,2,3]), OrderedSet{Int}([1,2,3]))
@test  isequal(OrderedSet{Int}([1,2,3]), OrderedSet{Any}([1,2,3]))
@test !isequal(OrderedSet{Any}([1,2,3]), OrderedSet{Int}([1,2,3,4]))
@test !isequal(OrderedSet{Int}([1,2,3]), OrderedSet{Any}([1,2,3,4]))
@test !isequal(OrderedSet{Any}([1,2,3,4]), OrderedSet{Int}([1,2,3]))
@test !isequal(OrderedSet{Int}([1,2,3,4]), OrderedSet{Any}([1,2,3]))

# eltype, similar
s1 = similar(OrderedSet([1,"hello"]))
@test isequal(s1, OrderedSet())
@test eltype(s1) === Any
s2 = similar(OrderedSet{Float32}([2.0f0,3.0f0,4.0f0]))
@test isequal(s2, OrderedSet())
@test eltype(s2) === Float32

# show
@test endswith(sprint(show, OrderedSet()), "OrderedSet{Any}()")
@test endswith(sprint(show, OrderedSet(['a'])), "OrderedSet{Char}(['a'])")

s = OrderedSet(); push!(s,1); push!(s,2); push!(s,3)
@test !isempty(s)
@test in(1,s)
@test in(2,s)
@test length(s) == 3
push!(s,1); push!(s,2); push!(s,3)
@test length(s) == 3
@test pop!(s,1) == 1
@test !in(1,s)
@test in(2,s)
@test length(s) == 2
@test_throws KeyError pop!(s,1)
@test pop!(s,1,:foo) == :foo
@test length(delete!(s,2)) == 1
@test !in(1,s)
@test !in(2,s)
@test pop!(s) == 3
@test length(s) == 0
@test isempty(s)

# copy
data_in = (1,2,9,8,4)
s = OrderedSet(data_in)
c = copy(s)
@test isequal(s,c)
v = pop!(s)
@test !in(v,s)
@test  in(v,c)
push!(s,100)
push!(c,200)
@test !in(100,c)
@test !in(200,s)

# sizehint!, empty
s = OrderedSet([1])
@test isequal(sizehint!(s, 10), OrderedSet([1]))
@test isequal(empty!(s), OrderedSet())
# TODO: rehash

# start, done, next
for data_in in ((7,8,4,5),
                ("hello", 23, 2.7, (), [], (1,8)))
    s = OrderedSet(data_in)

    s_new = OrderedSet()
    for el in s
        push!(s_new, el)
    end
    @test isequal(s, s_new)

    t = tuple(s...)

    @test t === data_in
    @test length(t) == length(s)
    for (e,f) in zip(t,s)
        @test e === f
    end
end

# union
@test isequal(union(OrderedSet([1])),OrderedSet([1]))
s = ∪(OrderedSet([1,2]), OrderedSet([3,4]))
@test isequal(s, OrderedSet([1,2,3,4]))
s = union(OrderedSet([5,6,7,8]), OrderedSet([7,8,9]))
@test isequal(s, OrderedSet([5,6,7,8,9]))
s = OrderedSet([1,3,5,7])
union!(s,(2,3,4,5))
# TODO: order is not the same, so isequal should return false...
@test isequal(s,OrderedSet([1,2,3,4,5,7]))

# intersect
@test isequal(intersect(OrderedSet([1])),OrderedSet([1]))
s = ∩(OrderedSet([1,2]), OrderedSet([3,4]))
@test isequal(s, OrderedSet())
s = intersect(OrderedSet([5,6,7,8]), OrderedSet([7,8,9]))
@test isequal(s, OrderedSet([7,8]))
@test isequal(intersect(OrderedSet([2,3,1]), OrderedSet([4,2,3]), OrderedSet([5,4,3,2])), OrderedSet([2,3]))

# indexing
s = OrderedSet([1,3,5,7])
@test s[1] == 1
@test s[2] == 3
@test s[end] == 7

# find
s = OrderedSet([1,3,5,7])
@test findfirst(s,1) == 1
@test findfirst(s,7) == 4
@test findfirst(s,2) == 0

# setdiff
@test isequal(setdiff(OrderedSet([1,2,3]), OrderedSet()),        OrderedSet([1,2,3]))
@test isequal(setdiff(OrderedSet([1,2,3]), OrderedSet([1])),     OrderedSet([2,3]))
@test isequal(setdiff(OrderedSet([1,2,3]), OrderedSet([1,2])),   OrderedSet([3]))
@test isequal(setdiff(OrderedSet([1,2,3]), OrderedSet([1,2,3])), OrderedSet())
@test isequal(setdiff(OrderedSet([1,2,3]), OrderedSet([4])),     OrderedSet([1,2,3]))
@test isequal(setdiff(OrderedSet([1,2,3]), OrderedSet([4,1])),   OrderedSet([2,3]))
s = OrderedSet([1,3,5,7])
setdiff!(s,(3,5))
@test isequal(s,OrderedSet([1,7]))
s = OrderedSet([1,2,3,4])
setdiff!(s, OrderedSet([2,4,5,6]))
@test isequal(s,OrderedSet([1,3]))

# ordering
@test OrderedSet() < OrderedSet([1])
@test OrderedSet([1]) < OrderedSet([1,2])
@test !(OrderedSet([3]) < OrderedSet([1,2]))
@test !(OrderedSet([3]) > OrderedSet([1,2]))
@test OrderedSet([1,2,3]) > OrderedSet([1,2])
@test !(OrderedSet([3]) <= OrderedSet([1,2]))
@test !(OrderedSet([3]) >= OrderedSet([1,2]))
@test OrderedSet([1]) <= OrderedSet([1,2])
@test OrderedSet([1,2]) <= OrderedSet([1,2])
@test OrderedSet([1,2]) >= OrderedSet([1,2])
@test OrderedSet([1,2,3]) >= OrderedSet([1,2])
@test !(OrderedSet([1,2,3]) >= OrderedSet([1,2,4]))
@test !(OrderedSet([1,2,3]) <= OrderedSet([1,2,4]))

# issubset, symdiff
for (l,r) in ((OrderedSet([1,2]),     OrderedSet([3,4])),
              (OrderedSet([5,6,7,8]), OrderedSet([7,8,9])),
              (OrderedSet([1,2]),     OrderedSet([3,4])),
              (OrderedSet([5,6,7,8]), OrderedSet([7,8,9])),
              (OrderedSet([1,2,3]),   OrderedSet()),
              (OrderedSet([1,2,3]),   OrderedSet([1])),
              (OrderedSet([1,2,3]),   OrderedSet([1,2])),
              (OrderedSet([1,2,3]),   OrderedSet([1,2,3])),
              (OrderedSet([1,2,3]),   OrderedSet([4])),
              (OrderedSet([1,2,3]),   OrderedSet([4,1])))
    @test issubset(intersect(l,r), l)
    @test issubset(intersect(l,r), r)
    @test issubset(l, union(l,r))
    @test issubset(r, union(l,r))
    @test isequal(union(intersect(l,r),symdiff(l,r)), union(l,r))
end
@test ⊆(OrderedSet([1]), OrderedSet([1,2]))

## TODO: not implemented for OrderedSets
#@test ⊊(OrderedSet([1]), OrderedSet([1,2]))
#@test !⊊(OrderedSet([1]), OrderedSet([1]))
#@test ⊈(OrderedSet([1]), OrderedSet([2]))

# TODO: returns false!
#       == is not properly defined for OrderedSets
#@test symdiff(OrderedSet([1,2,3,4]), OrderedSet([2,4,5,6])) == OrderedSet([1,3,5,6])
@test isequal(symdiff(OrderedSet([1,2,3,4]), OrderedSet([2,4,5,6])), OrderedSet([1,3,5,6]))

# filter
s = OrderedSet([1,2,3,4])
@test isequal(filter(isodd,s), OrderedSet([1,3]))
filter!(isodd, s)
@test isequal(s, OrderedSet([1,3]))

# first
@test_throws ArgumentError first(OrderedSet())
@test first(OrderedSet([2])) == 2

#####################


# empty set
d = OrderedSet{Char}()
@test length(d) == 0
@test isempty(d)
@test !('c' in d)
push!(d, 'c')
@test !isempty(d)
empty!(d)
@test isempty(d)

# access, modification

for c in 'a':'z'
    push!(d, c)
end

for c in 'a':'z'
    @test c in d
end

@test collect(d) == collect('a':'z')
