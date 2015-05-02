workspace()
using DataStructures
using Base.Test
using Compat

# construction
@test typeof(MultiDict()) == MultiDict{Any,Any}
@test typeof(MultiDict(())) == MultiDict{Any,Any}
@test eltype(MultiDict{Char,Int}()) == @compat Tuple{Char,Int}
@test typeof(MultiDict([('a',[1])])) == MultiDict{Char,Int}
@test typeof(MultiDict([('a',1)])) == MultiDict{Char,Int}
@test typeof(MultiDict([('a',1), ('a',[1])])) == MultiDict{Char,Any}

# if VERSION >= v"0.4.0-dev+980"
#     @test typeof(MultiDict(Pair(1, 1.0))) == MultiDict{Int,Float64}
#     @test typeof(MultiDict(Pair(1, 1.0), Pair(2, 2.0))) == MultiDict{Int,Float64}
#     @test typeof(MultiDict(Pair(1, 1.0), Pair(2, 2.0), Pair(3, 3.0))) == MultiDict{Int,Float64}
# end

# empty dictionary
d = MultiDict{Char, Int}()
@test length(d) == 0
@test isempty(d)
@test_throws KeyError d['c'] == 1
d['c'] = 1
@test !isempty(d)
empty!(d)
@test isempty(d)

# access, modification
d = MultiDict{Char,Int}()
for i in 1:15
    d[rand('a':'f')] = rand(1:10)
end

@test length(d) == 15
@test length(values(d)) == 15
@test length(keys(d)) <= 6
