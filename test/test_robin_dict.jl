using Test

include("../src/robin_dict.jl")

@testset "Constructors" begin
    h1 = RobinDict()
    @test length(h1) == 0
    @test isempty(h1) == true
    @test h1.totalcost == 0
    @test h1.idxfloor == 0
    @test length(h1.keys) == 16
    @test length(h1.vals) == 16
    @test length(h1.dibs) == 16
    @test length(h1.slots) == 16
    @test eltype(h1) == Pair{Any, Any}
    @test keytype(h1) == Any
    @test valtype(h1) == Any
end

@testset "RobinDict" begin
    h = RobinDict()
    for i=1:10000
        h[i] = i+1
    end
    for i=1:10000
        @test (h[i] == i+1)
    end
    for i=1:2:10000
        delete!(h, i)
    end
    for i=1:2:10000
        h[i] = i+1
    end
    for i=1:10000
        @test (h[i] == i+1)
    end
    for i=1:10000
        delete!(h, i)
    end
    @test isempty(h)
    h[77] = 100
    @test h[77] == 100
    for i=1:10000
        h[i] = i+1
    end
    for i=1:2:10000
        delete!(h, i)
    end
    for i=10001:20000
        h[i] = i+1
    end
    for i=2:2:10000
        @test h[i] == i+1
    end
    for i=10000:20000
        @test h[i] == i+1
    end
    h = RobinDict{Any,Any}("a" => 3)
    @test h["a"] == 3
    h["a","b"] = 4
    @test h["a","b"] == h[("a","b")] == 4
    h["a","b","c"] = 4
    @test h["a","b","c"] == h[("a","b","c")] == 4

    @testset "eltype, keytype and valtype" begin
        @test eltype(h) == Pair{Any,Any}
        @test keytype(h) == Any
        @test valtype(h) == Any

        td = RobinDict{AbstractString,Float64}()
        @test eltype(td) == Pair{AbstractString,Float64}
        @test keytype(td) == AbstractString
        @test valtype(td) == Float64
        @test keytype(Dict{AbstractString,Float64}) === AbstractString
        @test valtype(Dict{AbstractString,Float64}) === Float64
    end
    # test rethrow of error in ctor
    @test_throws DomainError RobinDict((sqrt(p[1]), sqrt(p[2])) for p in zip(-1:2, -1:2))
end

@testset "RobinDict on pairs" begin
	let x = RobinDict(3=>3, 5=>5, 8=>8, 6=>6)
	    pop!(x, 5)
	    for k in keys(x)
	        RobinDict{Int,Int}(x)
	        @test k in [3, 8, 6]
	    end
	end
end

@testset "KeyError" begin
    let z = RobinDict()
        get_KeyError = false
        try
            z["a"]
        catch _e123_
            get_KeyError = isa(_e123_,KeyError)
        end
        @test get_KeyError
    end
end

@testset "Filter function" begin
    _d = RobinDict("a"=>0)
    @test isa([k for k in filter(x->length(x)==1, collect(keys(_d)))], Vector{String})
end

@testset "typeof" begin
    d = RobinDict(((1, 2), (3, 4)))
    @test d[1] === 2
    @test d[3] === 4
    d2 = RobinDict(1 => 2, 3 => 4)
    d3 = RobinDict((1 => 2, 3 => 4))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == RobinDict{Int,Int}

    d = RobinDict(((1, 2), (3, "b")))
    @test d[1] === 2
    @test d[3] == "b"
    d2 = RobinDict(1 => 2, 3 => "b")
    d3 = RobinDict((1 => 2, 3 => "b"))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == RobinDict{Int,Any}

    d = RobinDict(((1, 2), ("a", 4)))
    @test d[1] === 2
    @test d["a"] === 4
    d2 = RobinDict(1 => 2, "a" => 4)
    d3 = RobinDict((1 => 2, "a" => 4))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == RobinDict{Any,Int}

    d = RobinDict(((1, 2), ("a", "b")))
    @test d[1] === 2
    @test d["a"] == "b"
    d2 = RobinDict(1 => 2, "a" => "b")
    d3 = RobinDict((1 => 2, "a" => "b"))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == RobinDict{Any,Any}
end

@testset "type of RobinDict constructed from varargs of Pairs" begin
    @test RobinDict(1=>1, 2=>2.0) isa RobinDict{Int,Any}
    @test RobinDict(1=>1, 2.0=>2) isa RobinDict{Any,Int}
    @test RobinDict(1=>1.0, 2.0=>2) isa RobinDict{Any,Any}

    for T in (Nothing, Missing)
        @test RobinDict(1=>1, 2=>T()) isa RobinDict{Int,Any}
        @test RobinDict(1=>T(), 2=>2) isa RobinDict{Int,Any}
        @test RobinDict(1=>1, T()=>2) isa RobinDict{Any,Int}
        @test RobinDict(T()=>1, 2=>2) isa RobinDict{Any,Int}
    end
end