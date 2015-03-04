using DataStructures
using Base.Test

# construction

@test typeof(OrderedSet()) == OrderedSet{Any}
@test typeof(OrderedSet(['a'])) == OrderedSet{Char}
@test typeof(OrderedSet([1,2,3,4])) == OrderedSet{Int}

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
