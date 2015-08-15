using DataStructures
using Base.Test

# construction
KVS = ('a',[1])
KV = ('a',1)
@test typeof(MultiDict()) == MultiDict{Any,Any}
@test typeof(MultiDict(())) == MultiDict{Any,Any}
@test typeof(MultiDict([KVS])) == MultiDict{Char,Int}
@test typeof(MultiDict([KV])) == MultiDict{Char,Int}
@test typeof(MultiDict([KV, KVS])) == MultiDict{Char,Any}

if VERSION >= v"0.4.0-dev+980"
    PVS = 1 => [1.0]
    PV = 1 => 1.0
    @test eltype(MultiDict{Char,Int}()) == Pair{Char,Vector{Int}}
    @test typeof(MultiDict(PVS)) == MultiDict{Int,Float64}
    @test typeof(MultiDict(PVS, PVS)) == MultiDict{Int,Float64}
    @test typeof(MultiDict([PVS, PVS])) == MultiDict{Int,Float64}
    @test typeof(MultiDict(PV)) == MultiDict{Int,Float64}
    @test typeof(MultiDict(PV, PV)) == MultiDict{Int,Float64}
    @test typeof(MultiDict([PV, PV])) == MultiDict{Int,Float64}
end

# setindex!, getindex, length, isempty, empty!, in
# copy, similar, get, haskey, getkey, start, next, done
d = MultiDict{Char,Int}()

@test length(d) == 0
@test isempty(d)

@test insert!(d, 'a', 1) == MultiDict{Char,Int}([('a', [1])])
@test getindex(d, 'a') == [1]
@test insert!(d, 'a', [2,3]) == MultiDict{Char,Int}([('a', [1,2,3])])
@test getindex(d, 'a') == [1,2,3]

@test_throws KeyError d['c'] == 1
insert!(d, 'c', 1)
@test collect(keys(d)) == ['c', 'a']
@test collect(values(d)) == Array{Int,1}[[1],[1,2,3]]

@test get(d, 'a', 0) == [1,2,3]
@test get(d, 'b', 0) == 0

@test haskey(d, 'a')
@test !haskey(d, 'b')
@test getkey(d, 'a', 0) == 'a'
@test getkey(d, 'b', 0) == 0

@test copy(d) == d
@test similar(d) == MultiDict{Char,Int}()

if VERSION >= v"0.4.0-dev+980"
    @test [kv for kv in d] == [Pair('c', [1]), Pair('a', [1,2,3])]
else
    @test [kv for kv in d] == [('c', [1]), ('a', [1,2,3])]
end

@test in(('c', 1), d)
@test in(('a', 1), d)
@test in(('c', [1]), d)
@test in(('a', [1,2,3]), d)

@test !isempty(d)
empty!(d)
@test isempty(d)

# pop!
d = MultiDict{Char,Int}([('a', [1,2,3]), ('c', [1])])
@test_throws KeyError pop!(d, 'b')
@test pop!(d, 'a') == 3
@test pop!(d, 'a') == 2
@test pop!(d, 'a') == 1
@test !haskey(d, 'a')
@test pop!(d, 'b', 0) == 0

# delete!
d = MultiDict{Char,Int}([('a', [1,2,3]), ('c', [1])])
@test delete!(d, 'b') == d
@test delete!(d, 'a') == MultiDict{Char,Int}([('c', [1])])

# setindex!
d = MultiDict{Char,Int}()
@test insert!(d, 'a', 1) == MultiDict{Char,Int}([('a', [1])])
@test insert!(d, 'a', 1) == MultiDict{Char,Int}([('a', [1, 1])])

# push!
d = MultiDict{Char,Int}()
@test push!(d, ('a',[1])) == MultiDict{Char,Int}([('a', [1])])
@test push!(d, ('a',[1])) == MultiDict{Char,Int}([('a', [1,1])])
empty!(d)
@test push!(d, ('a',1)) == MultiDict{Char,Int}([('a', [1])])
@test push!(d, ('a',1)) == MultiDict{Char,Int}([('a', [1,1])])

if VERSION >= v"0.4.0-dev+980"
    empty!(d)
    @test push!(d,'a'=>[1]) == MultiDict{Char,Int}([('a', [1])])
    @test push!(d, 'a'=>1) == MultiDict{Char,Int}([('a', [1,1])])
end

# get!
@test get!(d, 'a', []) == [1,1]
@test get!(d, 'b', []) == Int[]
@test get!(d, 'c', [1]) == [1]
@test_throws MethodError get!(d, 'd', 1)

# special functions: count, enumerateall
d = MultiDict{Char,Int}()
@test count(d) == 0
for i in 1:15
    insert!(d, rand('a':'f'), rand()>0.5 ? rand(1:10) : rand(1:10, rand(1:3)))
end
@test 15 <= count(d) <=45
@test size(d) == (length(d), count(d))

allvals = [kv for kv in enumerateall(d)]
@test length(allvals) == count(d)
@test all(kv->in(kv,d), enumerateall(d))

# @test length(d) == 15
# @test length(values(d)) == 15
# @test length(keys(d)) <= 6
