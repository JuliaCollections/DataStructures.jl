using DataStructures
using Base.Test

# construction

@test typeof(OrderedDict()) == OrderedDict{Any,Any}
@test typeof(OrderedDict(1,2.0)) == OrderedDict{Int,Float64}
@test typeof(OrderedDict([("a",1),("b",2)])) == OrderedDict{ASCIIString,Int}
if VERSION >= v"0.4-"
    @test typeof(OrderedDict(1 => 1.0)) == OrderedDict{Int,Float64}
    @test typeof(OrderedDict(1 => 1.0, 2 => 2.0)) == OrderedDict{Int,Float64}
    @test typeof(OrderedDict(1 => 1.0, 2 => 2.0, 3 => 3.0)) == OrderedDict{Int,Float64}
end

# empty dictionary
d = OrderedDict(Char, Int)
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

@test collect(keys(d)) == ['b':'z']
@test collect(values(d)) == [2:26]
@test collect(d) == [(a,i) for (a,i) in zip('b':'z', 2:26)]

# Test for #60

od60 = OrderedDict{Int,Int}()
od60[1] = 2

ranges = [2:5,6:9,10:13]
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
