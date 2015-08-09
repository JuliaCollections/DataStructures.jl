using DataStructures
using Base.Test

# construction

@test typeof(OrderedDict()) == OrderedDict{Any,Any}
@test typeof(OrderedDict([(1,2.0)])) == OrderedDict{Int,Float64}
@test typeof(OrderedDict([("a",1),("b",2)])) == OrderedDict{ASCIIString,Int}
if VERSION >= v"0.4.0-dev+980"
    @test typeof(OrderedDict(Pair(1, 1.0))) == OrderedDict{Int,Float64}
    @test typeof(OrderedDict(Pair(1, 1.0), Pair(2, 2.0))) == OrderedDict{Int,Float64}
    @test typeof(OrderedDict(Pair(1, 1.0), Pair(2, 2.0), Pair(3, 3.0))) == OrderedDict{Int,Float64}
end

# empty dictionary
d = OrderedDict{Char, Int}()
@test length(d) == 0
@test isempty(d)
@test_throws KeyError d['c'] == 1
d['c'] = 1
@test !isempty(d)
empty!(d)
@test isempty(d)

# access, modification

for c in 'a':'z'
    d[c] = c-'a'+1
end

@test (d['a'] += 1) == 2
@test 'a' in keys(d)
@test haskey(d, 'a')
@test get(d, 'B', 0) == 0
@test !('B' in keys(d))
@test !haskey(d, 'B')
@test pop!(d, 'a') == 2

@test collect(keys(d)) == collect('b':'z')
@test collect(values(d)) == collect(2:26)
if VERSION >= v"0.4.0-dev+980"
    @test collect(d) == [Pair(a,i) for (a,i) in zip('b':'z', 2:26)]
else
    @test collect(d) == [(a,i) for (a,i) in zip('b':'z', 2:26)]
end

# Test for #60

od60 = OrderedDict{Int,Int}()
od60[1] = 2

ranges = Range[2:5,6:9,10:13]
for range in ranges
    for i = range
        od60[i] = i+1
    end
    for i = range
        delete!( od60, i )
    end
end
od60[14]=15

@test od60[14] == 15


##############################
# Copied and modified from Base/test/dict.jl

# OrderedDict
h = OrderedDict{Int,Int}()
for i=1:10000
    h[i] = i+1
end

if VERSION >= v"0.4.0-dev+980"
    @test collect(h) == [Pair(x,y) for (x,y) in zip(1:10000, 2:10001)]
else
    @test collect(h) == collect(zip(1:10000, 2:10001))
end

for i=1:2:10000
    delete!(h, i)
end
for i=1:2:10000
    h[i] = i+1
end

for i=1:10000
    @test h[i]==i+1
end

for i=1:10000
    delete!(h, i)
end
@test isempty(h)

h[77] = 100
@test h[77]==100

for i=1:10000
    h[i] = i+1
end

for i=1:2:10000
    delete!(h, i)
end

for i=10001:20000
    h[i] = i+1
end

for i=2:2:10000
    @test h[i]==i+1
end

for i=10000:20000
    @test h[i]==i+1
end

h = OrderedDict{Any,Any}([("a", 3)])
@test h["a"] == 3
h["a","b"] = 4
@test h["a","b"] == h[("a","b")] == 4
h["a","b","c"] = 4
@test h["a","b","c"] == h[("a","b","c")] == 4

let
    z = OrderedDict()
    get_KeyError = false
    try
        z["a"]
    catch _e123_
        get_KeyError = isa(_e123_,KeyError)
    end
    @test get_KeyError
end

_d = OrderedDict([("a", 0)])
@test isa([k for k in filter(x->length(x)==1, collect(keys(_d)))], Vector{Any})

let
    ## TODO: this should work, but inference seems to be working incorrectly
    #d = OrderedDict(((1, 2), (3, 4)))
    d = OrderedDict([(1, 2), (3, 4)])
    @test d[1] === 2
    @test d[3] === 4
    ## TODO: @compat only rewrites Dict, not OrderedDict
    # d2 = OrderedDict(1 => 2, 3 => 4)
    # d3 = OrderedDict((1 => 2, 3 => 4))
    # @test d == d2 == d3
    # @test typeof(d) == typeof(d2) == typeof(d3) == OrderedDict{Int,Int}
    @test typeof(d) == OrderedDict{Int,Int}

    #d = OrderedDict(((1, 2), (3, "b")))
    d = OrderedDict([(1, 2), (3, "b")])
    @test d[1] === 2
    @test d[3] == "b"
    # d2 = OrderedDict(1 => 2, 3 => "b")
    # d3 = OrderedDict((1 => 2, 3 => "b"))
    # @test d == d2 == d3
    # @test typeof(d) == typeof(d2) == typeof(d3) == OrderedDict{Int,Any}
    @test typeof(d) == OrderedDict{Int,Any}

    #d = OrderedDict(((1, 2), ("a", 4)))
    d = OrderedDict([(1, 2), ("a", 4)])
    @test d[1] === 2
    @test d["a"] === 4
    # d2 = OrderedDict(1 => 2, "a" => 4)
    # d3 = OrderedDict((1 => 2, "a" => 4))
    # @test d == d2 == d3
    # @test typeof(d) == typeof(d2) == typeof(d3) == OrderedDict{Any,Int}
    @test typeof(d) == OrderedDict{Any,Int}

    #d = OrderedDict(((1, 2), ("a", "b")))
    d = OrderedDict([(1, 2), ("a", "b")])
    @test d[1] === 2
    @test d["a"] == "b"
    # d2 = OrderedDict(1 => 2, "a" => "b")
    # d3 = OrderedDict((1 => 2, "a" => "b"))
    # @test d == d2 == d3
    # @test typeof(d) == typeof(d2) == typeof(d3) == OrderedDict{Any,Any}
    @test typeof(d) == OrderedDict{Any,Any}
end

# TODO: this is a BoundsError on v0.3, ArgumentError on v0.4
#@test_throws ArgumentError first(OrderedDict())

if VERSION >= v"0.4.0-dev+980"
    @test first(OrderedDict([(:f, 2)])) == Pair(:f,2)
else
    @test first(OrderedDict([(:f, 2)])) == (:f,2)
end

# issue #1821
let
    d = OrderedDict{UTF8String, Vector{Int}}()
    d["a"] = [1, 2]
    @test_throws MethodError d["b"] = 1
    @test isa(repr(d), AbstractString)  # check that printable without error
end

# issue #2344
let
    local bar
    bestkey(d, key) = key
    bestkey{K<:AbstractString,V}(d::Associative{K,V}, key) = string(key)
    bar(x) = bestkey(x, :y)
    @test bar(OrderedDict([(:x, [1,2,5])])) == :y
    @test bar(OrderedDict([("x", [1,2,5])])) == "y"
end


@test  isequal(OrderedDict(), OrderedDict())
@test  isequal(OrderedDict([(1, 1)]), OrderedDict([(1, 1)]))
@test !isequal(OrderedDict([(1, 1)]), OrderedDict())
@test !isequal(OrderedDict([(1, 1)]), OrderedDict([(1, 2)]))
@test !isequal(OrderedDict([(1, 1)]), OrderedDict([(2, 1)]))

# Generate some data to populate dicts to be compared
data_in = [ (rand(1:1000), randstring(2)) for _ in 1:1001 ]

# Populate the first dict
d1 = OrderedDict{Int, ASCIIString}()
for (k,v) in data_in
    d1[k] = v
end
data_in = collect(d1)
# shuffle the data
for i in 1:length(data_in)
    j = rand(1:length(data_in))
    data_in[i], data_in[j] = data_in[j], data_in[i]
end
# Inserting data in different (shuffled) order should result in
# equivalent dict.
d2 = OrderedDict{Int, AbstractString}()
for (k,v) in data_in
    d2[k] = v
end

@test  isequal(d1, d2)
d3 = copy(d2)
d4 = copy(d2)
# Removing an item gives different dict
delete!(d1, data_in[rand(1:length(data_in))][1])
@test !isequal(d1, d2)
# Changing a value gives different dict
d3[data_in[rand(1:length(data_in))][1]] = randstring(3)
!isequal(d1, d3)
# Adding a pair gives different dict
d4[1001] = randstring(3)
@test !isequal(d1, d4)

@test isequal(OrderedDict(), sizehint(OrderedDict(),96))

# Here is what currently happens when dictionaries of different types
# are compared. This is not necessarily desirable. These tests are
# descriptive rather than proscriptive.
@test !isequal(OrderedDict([(1, 2)]), OrderedDict([("dog", "bone")]))
@test isequal(OrderedDict{Int,Int}(), OrderedDict{AbstractString,AbstractString}())

# get! (get with default values assigned to the given location)

## TODO: get! not implemented for OrderedDict
# let f(x) = x^2, d = OrderedDict((8, 19))

#     @test get!(d, 8, 5) == 19
#     @test get!(d, 19, 2) == 2

#     @test get!(d, 42) do  # d is updated with f(2)
#         f(2)
#     end == 4

#     @test get!(d, 42) do  # d is not updated
#         f(200)
#     end == 4

#     @test get(d, 13) do   # d is not updated
#         f(4)
#     end == 16

#     @test d == OrderedDict((8, 19), (19, 2), (42, 4))
# end


# issue #5886
d5886 = OrderedDict()
for k5886 in 1:11
   d5886[k5886] = 1
end
for k5886 in keys(d5886)
   # undefined ref if not fixed
   d5886[k5886] += 1
end

# issue #8877
## TODO: merge not implemented for OrderedDict
# let
#     a = OrderedDict("foo"  => 0.0, "bar" => 42.0)
#     b = OrderedDict("フー" => 17, "バー" => 4711)
#     @test is(typeof(merge(a, b)), OrderedDict{UTF8String,Float64})
# end

# issue 9295
let
    d = OrderedDict()
    @test is(push!(d, ('a', 1)), d)
    @test d['a'] == 1
    @test is(push!(d, ('b', 2), ('c', 3)), d)
    @test d['b'] == 2
    @test d['c'] == 3
    @test is(push!(d, ('d', 4), ('e', 5), ('f', 6)), d)
    @test d['d'] == 4
    @test d['e'] == 5
    @test d['f'] == 6
    @test length(d) == 6
end
