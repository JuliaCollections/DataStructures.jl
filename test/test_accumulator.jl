# Test of accumulators

@testset "Accumulators" begin

    ct = counter(String)
    
    @testset "Core Functionality" begin
        @assert isa(ct, Accumulator{String,Int})

        @test ct["abc"] == 0
        @test !haskey(ct, "abc")
        @test isempty(collect(keys(ct)))
    end

    @testset "Test setindex!" begin
        ct["b"] = 2
        @test ct["b"] == 2
        ct["b"] = 0
        @test ct["b"] == 0
    end

    @testset "Test inc!" begin
        inc!(ct, "a")
        @test haskey(ct, "a")
        @test ct["a"] == 1

        inc!(ct, "b", 2)
        @test haskey(ct, "b")
        @test ct["b"] == 2
    end

    @testset "Test dec!" begin
        dec!(ct, "b")
        @test ct["b"] == 1
        dec!(ct, "b", 16)
        @test ct["b"] == -15
        ct["b"] = 2
    end

    @testset "Test convert" begin
        inc!(ct, "b", 0x3)
        @test ct["b"] == 5

        @test !haskey(ct, "abc")
        @test ct["abc"] == 0

        @test length(ct) == 2
        @test length(collect(ct)) == 2
        @test length(collect(keys(ct))) == 2
        @test length(collect(values(ct))) == 2
        @test sum(ct) == 6
    end

    @testset "From Vector" begin
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
    end

    @testset "From Dict" begin
        ct3 = counter(Dict([("a",10), ("b",20)]))
        @test isa(ct3, Accumulator{String,Int})
        @test haskey(ct3, "a")
        @test haskey(ct3, "b")
        @test ct3["a"] == 10
        @test ct3["b"] == 20

        ct2 = counter(["a", "a", "b", "b", "a", "c", "c"])
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
    end

    @testset "From Pair" begin
        ct4 = counter(Pair{Int,Int})
        @test isa(ct4, Accumulator{Pair{Int,Int}})
        @test push!(ct4, 1=>2) == 1
        @test push!(ct4, 1=>2) == 2
    end

    @testset "From Dict / merge / merge!" begin
        ct5 = counter(Dict([("a",10), ("b",20)]))
        @test merge(ct5)==ct5
        @test merge!(ct5)===ct5
        @test merge(ct5,ct5,ct5)==counter(Dict([("a",30), ("b",60)]))
    end

    @testset "Counter equality/inequality" begin
        @test counter([2,3,4,4]) == counter([4,2,3,4])
        @test counter([2,3,4,4]) != counter([4,2,3,4,4])
    end

    @testset "Array{SubString{String},1}" begin
        ct5 = counter(split("a b b c c c"))
        @test ct5["a"] == 1
        @test ct5["b"] == 2
        @test ct5["c"] == 3
    end

    @testset "ct6" begin
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
    end

    @testset "Generators" begin
        s = ["y", "el", "sol", "se", "fue"]
        @test counter(length(x) for x in s) == counter(map(length, s))
    end

    @testset "non-integer uses" begin
        acc = Accumulator{Symbol, Float16}()
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

    @testset "nlargest" begin
        @test nlargest(counter("abbbcddddda")) == ['d'=>5, 'b'=>3, 'a'=>2, 'c'=>1]
        @test nlargest(counter("abbbccddddda"),2) == ['d'=>5, 'b'=>3]
        @test nlargest(counter("a")) == ['a'=>1]

        @test nlargest(counter("aaabbcc")) ∈ (['a'=>3,'b'=>2, 'c'=>2], ['a'=>3,'c'=>2, 'b'=>2])


        @test_throws BoundsError nlargest(counter("a"),2)
    end

    @testset "nsmallest" begin
        acc = counter("aabbbcccc")
        @test nsmallest(acc) == ['a'=>2, 'b'=>3, 'c'=>4]
        @test nsmallest(acc,2) == ['a'=>2, 'b'=>3]
        acc['d']=0
        @test nsmallest(acc,2) == ['d'=>0, 'a'=>2]

        @test nsmallest(counter("aaabbcc")) ∈ (['b'=>2, 'c'=>2, 'a'=>3], ['c'=>2, 'b'=>2, 'a'=>3])

        @test_throws BoundsError nsmallest(counter("a"),2)
    end

end # @testset Accumulators



