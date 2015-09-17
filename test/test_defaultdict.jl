using DataStructures
using Base.Test

##############
# DefaultDicts
##############

# construction
@test_throws ErrorException DefaultDict()
@test_throws ErrorException DefaultDict(AbstractString, Int)

if VERSION >= v"0.4.0-dev+980"
    @test typeof(DefaultDict(0.0, 1 => 1.0)) == DefaultDict{Int,Float64,Float64}
end

# empty dictionary
d = DefaultDict(Char, Int, 1)
@test length(d) == 0
@test isempty(d)
@test d['c'] == 1
@test !isempty(d)
empty!(d)
@test isempty(d)

# access, modification
@test (d['a'] += 1) == 2
@test 'a' in keys(d)
@test haskey(d, 'a')
@test get(d, 'b', 0) == 0
@test !('b' in keys(d))
@test !haskey(d, 'b')
@test pop!(d, 'a') == 2
@test isempty(d)

for c in 'a':'z'
    d[c] = c-'a'+1
end

@test d['z'] == 26
@test d['@'] == 1
@test length(d) == 27
delete!(d, '@')
@test length(d) == 26

for (k,v) in d
    @test v == k-'a'+1
end

@test sort(collect(keys(d))) == collect('a':'z')
@test sort(collect(values(d))) == collect(1:26)

# Starting from an existing dictionary
# Note: dictionary is copied upon construction
e = Dict([('a',1), ('b',3), ('c',5)])
f = DefaultDict(0, e)
@test f['d'] == 0
@test_throws KeyError e['d']
e['e'] = 9
@test e['e'] == 9
@test f['e'] == 0

s = similar(d)
@test typeof(s) == typeof(d)
@test s.d.default == d.d.default


#####################
# DefaultOrderedDicts
#####################

# construction
@test_throws ErrorException DefaultOrderedDict()
@test_throws ErrorException DefaultOrderedDict(AbstractString, Int)

# empty dictionary
d = DefaultOrderedDict(Char, Int, 1)
@test length(d) == 0
@test isempty(d)
@test d['c'] == 1
@test !isempty(d)
empty!(d)
@test isempty(d)

# access, modification
@test (d['a'] += 1) == 2
@test 'a' in keys(d)
@test haskey(d, 'a')
@test get(d, 'b', 0) == 0
@test !('b' in keys(d))
@test !haskey(d, 'b')
@test pop!(d, 'a') == 2
@test isempty(d)

for c in 'a':'z'
    d[c] = c-'a'+1
end

@test d['z'] == 26
@test d['@'] == 1
@test length(d) == 27
delete!(d, '@')
@test length(d) == 26

for (k,v) in d
    @test v == k-'a'+1
end

@test collect(keys(d)) == collect('a':'z')
@test collect(values(d)) == collect(1:26)

s = similar(d)
@test typeof(s) == typeof(d)
@test s.d.default == d.d.default
