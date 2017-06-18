# Test classified collections

using DataStructures
if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

# classified lists

c = classified_lists(Compat.ASCIIString, Int)

push!(c, "low", 1)
push!(c, "low", 2)
push!(c, "low", 3)
push!(c, "high", 4)
push!(c, "high", 5)

@test haskey(c, "low")
@test haskey(c, "high")
@test !haskey(c, "mid")

@test c["low"] == [1, 2, 3]
@test c["high"] == [4, 5]

@test length(c) == 2
@test sort(collect(keys(c))) == Compat.ASCIIString["high","low"]

pop!(c,"low")
@test !haskey(c,"low")

# classified sets

c = classified_sets(Compat.ASCIIString, Int)

push!(c, "low", 1)
push!(c, "low", 2)
push!(c, "low", 3)
push!(c, "low", 1)
push!(c, "low", 2)

push!(c, "high", 4)
push!(c, "high", 5)
push!(c, "high", 5)

@test haskey(c, "low")
@test haskey(c, "high")
@test !haskey(c, "mid")

@test isa(c["low"], Set{Int})
@test isa(c["high"], Set{Int})

@test sort(collect(c["low"])) == [1, 2, 3]
@test sort(collect(c["high"])) == [4, 5]

# classified counters

c = classified_counters(Compat.ASCIIString, Float64)

push!(c, "low", 1.)
push!(c, "low", 2.)
push!(c, "low", 3.)
push!(c, "low", 1.)
push!(c, "low", 2.)
push!(c, "low", 2.)

push!(c, "high", 4.)
push!(c, "high", 5.)
push!(c, "high", 5.)

@test haskey(c, "low")
@test haskey(c, "high")
@test !haskey(c, "mid")

cl = c["low"]
ch = c["high"]

@test isa(cl, Accumulator{Float64, Int})
@test isa(ch, Accumulator{Float64, Int})

@test cl[1.] == 2
@test cl[2.] == 3
@test cl[3.] == 1
@test ch[4.] == 1
@test ch[5.] == 2
