# Test of accumulators

ct = counter(ASCIIString)
@assert isa(ct, Accumulator{ASCIIString,Int})

@test ct["abc"] == 0
@test !haskey(ct, "abc")
@test isempty(collect(keys(ct)))

push!(ct, "a")
@test haskey(ct, "a")
@test ct["a"] == 1

push!(ct, "b", 2)
@test haskey(ct, "b")
@test ct["b"] == 2

# Test convert
push!(ct, "b", 0x3)
@test ct["b"] == 5

@test !haskey(ct, "abc")
@test ct["abc"] == 0

@test length(ct) == 2
@test length(collect(ct)) == 2
@test length(collect(keys(ct))) == 2
@test length(collect(values(ct))) == 2
@test sum(ct) == 6

ct2 = counter(["a", "a", "b", "b", "a", "c", "c"])
@test isa(ct2, Accumulator{ASCIIString,Int})
@test haskey(ct2, "a")
@test haskey(ct2, "b")
@test haskey(ct2, "c")
@test ct2["a"] == 3
@test ct2["b"] == 2
@test ct2["c"] == 2

push!(ct, ct2)
@test ct["a"] == 4
@test ct["b"] == 7
@test ct["c"] == 2

ct3 = counter(Dict([("a",10), ("b",20)]))
@test isa(ct3, Accumulator{ASCIIString,Int})
@test haskey(ct3, "a")
@test haskey(ct3, "b")
@test ct3["a"] == 10
@test ct3["b"] == 20

ctm = merge(ct2, ct3)
@test isa(ctm, Accumulator{ASCIIString,Int})
@test haskey(ctm, "a")
@test haskey(ctm, "b")
@test haskey(ctm, "c")
@test ctm["a"] == 13
@test ctm["b"] == 22
@test ctm["c"] == 2

@test pop!(ctm, "b") == 22
@test !haskey(ctm, "b")
@test ctm["b"] == 0

mc = most_common(ct3)
@test isa(mc, Array{Pair{ASCIIString,Int64},1})
@test mc == [Pair("b", 20), Pair("a", 10)]
