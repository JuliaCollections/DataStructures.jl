using DataStructures
using Base.Test

# construction
@test_throws DefaultDict()
@test_throws DefaultDict(String, Int)

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

@test sort(collect(keys(d))) == ['a':'z']
@test sort(collect(values(d))) == [1:26]

# Starting from an existing dictionary
e = ['a'=>1, 'b'=>3, 'c'=>5]
f = DefaultDict(0, e)
@test_throws e['d']
@test f['d'] == 0
f['e'] = 9
@test e['d'] == 0
@test e['e'] == 9
