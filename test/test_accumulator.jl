# Test of accumulators

@testset "Accumulators" begin

    ct = counter(String)
    @assert isa(ct, Accumulator{String,Int})

    @test ct["abc"] == 0
    @test !haskey(ct, "abc")
    @test isempty(collect(keys(ct)))

    # Test setindex!
    ct["b"] = 2
    @test ct["b"] == 2
    ct["b"] = 0
    @test ct["b"] == 0



    inc!(ct, "a")
    @test haskey(ct, "a")
    @test ct["a"] == 1

    inc!(ct, "b", 2)
    @test haskey(ct, "b")
    @test ct["b"] == 2

    # Test dec!
    dec!(ct, "b")
    @test ct["b"] == 1
    dec!(ct, "b", 16)
    @test ct["b"] == -15
    ct["b"] = 2     

    # Test convert
    inc!(ct, "b", 0x3)
    @test ct["b"] == 5

    @test !haskey(ct, "abc")
    @test ct["abc"] == 0

    @test length(ct) == 2
    @test length(collect(ct)) == 2
    @test length(collect(keys(ct))) == 2
    @test length(collect(values(ct))) == 2
    @test sum(ct) == 6

    ct2 = counter(["a", "a", "b", "b", "a", "c", "c"])
    @test isa(ct2, Accumulator{String,Int})
    @test haskey(ct2, "a")
    @test haskey(ct2, "b")
    @test haskey(ct2, "c")
    @test ct2["a"] == 3
    @test ct2["b"] == 2
    @test ct2["c"] == 2

    merge!(ct, ct2)
    @test ct["a"] == 4
    @test ct["b"] == 7
    @test ct["c"] == 2

    ct3 = counter(Dict([("a",10), ("b",20)]))
    @test isa(ct3, Accumulator{String,Int})
    @test haskey(ct3, "a")
    @test haskey(ct3, "b")
    @test ct3["a"] == 10
    @test ct3["b"] == 20

    ctm = merge(ct2, ct3)
    @test isa(ctm, Accumulator{String,Int})
    @test haskey(ctm, "a")
    @test haskey(ctm, "b")
    @test haskey(ctm, "c")
    @test ctm["a"] == 13
    @test ctm["b"] == 22
    @test ctm["c"] == 2

    @test reset!(ctm, "b") == 22
    @test !haskey(ctm, "b")
    @test ctm["b"] == 0

    ct4 = counter(Pair{Int,Int})
    @test isa(ct4, Accumulator{Pair{Int,Int}})
    @test push!(ct4, 1=>2) == 1
    @test push!(ct4, 1=>2) == 2

    ct5 = counter(Dict([("a",10), ("b",20)]))
    @test merge(ct5)==ct5
    @test merge!(ct5)===ct5
    @test merge(ct5,ct5,ct5)==counter(Dict([("a",30), ("b",60)]))

    @test counter([2,3,4,4]) == counter([4,2,3,4])
    @test counter([2,3,4,4]) != counter([4,2,3,4,4])


    ct5 = counter(split("a b b c c c"))
    @test ct5["a"] == 1
    @test ct5["b"] == 2
    @test ct5["c"] == 3

    ct6 = counter(["a", "b" , "b", "c", "c", "c"])
    for ii in split("a b c")
        inc!(ct6, ii)
    end
    @test ct6["a"] == 2
    @test ct6["b"] == 3
    @test ct6["c"] == 4
    for ii in split("a b")
        reset!(ct6, ii)
    end
    @test ct6["a"] == 0
    @test ct6["b"] == 0
    @test ct6["c"] == 4


    @testset "Generators" begin
        s = ["y", "el", "sol", "se", "fue"]
        @test counter(length(x) for x in s) == counter(map(length, s))
    end

    @testset "non-integer uses" begin
        acc = Accumulator(Symbol, Float16)
        acc[:a] = 1.5
        @test acc[:a] ≈ 1.5
        push!(acc, :a, 2.5)
        @test acc[:a] ≈ 4.0
        dec!(acc, :a)
        @test acc[:a] ≈ 3.0
    end

    @testset "ambiguity resolution" begin
        ct7 = counter(Int)
        @test_throws MethodError push!(ct7, 1=>2)
    end

	@testset "most common" begin
		@test most_common(counter("abbbccddddda")) == ['d'=>5, 'b'=>3, 'a'=>2, 'c'=>2]
		@test most_common(counter("abbbccddddda"),2) == ['d'=>5, 'b'=>3]
		@test most_common(counter("a")) == ['a'=>1]

		@test_throws BoundsError most_common(counter("a"),2)
	end

    @testset "deprecations" begin
        ctd = counter([1,2,3])
        @test ctd[3]==1

        println("\nThe following warning is expected:")
        @test pop!(ctd, 3)==1
        println("\nThe following warning is expected:")
        @test push!(counter([1,2,3]),counter([1,2,3])) == merge!(counter([1,2,3]), counter([1,2,3]))
    end
end # @testset Accumulators



