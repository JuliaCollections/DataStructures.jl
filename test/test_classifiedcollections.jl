# Test classified collections

using DataStructures
using Base.Test

# classified lists

c = classified_lists(ASCIIString, Int)

add!(c, "low", 1)
add!(c, "low", 2)
add!(c, "low", 3)
add!(c, "high", 4)
add!(c, "high", 5)

@test haskey(c, "low")
@test haskey(c, "high")
@test !haskey(c, "mid")

@test c["low"] == [1, 2, 3]
@test c["high"] == [4, 5]

# classified sets

c = classified_sets(ASCIIString, Int)

add!(c, "low", 1)
add!(c, "low", 2)
add!(c, "low", 3)
add!(c, "low", 1)
add!(c, "low", 2)

add!(c, "high", 4)
add!(c, "high", 5)
add!(c, "high", 5)

@test haskey(c, "low")
@test haskey(c, "high")
@test !haskey(c, "mid")

@test isa(c["low"], Set{Int})
@test isa(c["high"], Set{Int})

@test sort(collect(c["low"])) == [1, 2, 3]
@test sort(collect(c["high"])) == [4, 5]

# classified counters

c = classified_counters(ASCIIString, Float64)

add!(c, "low", 1.)
add!(c, "low", 2.)
add!(c, "low", 3.)
add!(c, "low", 1.)
add!(c, "low", 2.)
add!(c, "low", 2.)

add!(c, "high", 4.)
add!(c, "high", 5.)
add!(c, "high", 5.)

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

