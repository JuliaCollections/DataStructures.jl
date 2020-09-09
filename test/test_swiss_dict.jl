@testset "Constructors" begin
    h1 = SwissDict()
    @test length(h1) == 0
    @test isempty(h1) == true
    @test h1.idxfloor == 1
    @test length(h1.keys) == 16
    @test length(h1.vals) == 16
    @test length(h1.slots) == 1
    @test eltype(h1) == Pair{Any, Any}
    @test keytype(h1) == Any
    @test valtype(h1) == Any
end

@testset "SwissDict" begin
    h = SwissDict()
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
    h = SwissDict{Any,Any}("a" => 3)
    @test h["a"] == 3
    h["a","b"] = 4
    @test h["a","b"] == h[("a","b")] == 4
    h["a","b","c"] = 4
    @test h["a","b","c"] == h[("a","b","c")] == 4

    @testset "eltype, keytype and valtype" begin
        @test eltype(h) == Pair{Any,Any}
        @test keytype(h) == Any
        @test valtype(h) == Any

        td = SwissDict{AbstractString,Float64}()
        @test eltype(td) == Pair{AbstractString,Float64}
        @test keytype(td) == AbstractString
        @test valtype(td) == Float64
        @test keytype(Dict{AbstractString,Float64}) === AbstractString
        @test valtype(Dict{AbstractString,Float64}) === Float64
    end
    # test rethrow of error in ctor
    @test_throws DomainError SwissDict((sqrt(p[1]), sqrt(p[2])) for p in zip(-1:2, -1:2))
end

@testset "SwissDict on pairs" begin
	let x = SwissDict(3=>3, 5=>5, 8=>8, 6=>6)
	    pop!(x, 5)
	    for k in keys(x)
	        SwissDict{Int,Int}(x)
	        @test k in [3, 8, 6]
	    end
	end
    
    let y = SwissDict{Any, Int}(3=>3, 5=>5, "8"=>8, 6=>6)
        pop!(y, "8")
        for k in keys(y)
            SwissDict{Int,Int}(y)
            @test k in [3, 5, 6]
        end
    end

    d = @inferred SwissDict(Pair(1,1), Pair(2,2), Pair(3,3))
    @test isa(d, SwissDict)
    @test d == SwissDict(1=>1, 2=>2, 3=>3)
    @test eltype(d) == Pair{Int,Int}
end

@testset "KeyError" begin
    let z = SwissDict()
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
    _d = SwissDict("a"=>0)
    @test isa([k for k in filter(x->length(x)==1, collect(keys(_d)))], Vector{String})
    
    h = SwissDict{Int, Int}()
    for i in 1:100
        h[i] = i
    end
    filter!(x->isodd(x.first), h)
    for i in 1:2:100
        @test h[i] == i
    end
end

@testset "typeof" begin
    d = SwissDict(((1, 2), (3, 4)))
    @test d[1] === 2
    @test d[3] === 4
    d2 = SwissDict(1 => 2, 3 => 4)
    d3 = SwissDict((1 => 2, 3 => 4))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == SwissDict{Int,Int}

    d = SwissDict(((1, 2), (3, "b")))
    @test d[1] === 2
    @test d[3] == "b"
    d2 = SwissDict(1 => 2, 3 => "b")
    d3 = SwissDict((1 => 2, 3 => "b"))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == SwissDict{Int,Any}

    d = SwissDict(((1, 2), ("a", 4)))
    @test d[1] === 2
    @test d["a"] === 4
    d2 = SwissDict(1 => 2, "a" => 4)
    d3 = SwissDict((1 => 2, "a" => 4))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == SwissDict{Any,Int}

    d = SwissDict(((1, 2), ("a", "b")))
    @test d[1] === 2
    @test d["a"] == "b"
    d2 = SwissDict(1 => 2, "a" => "b")
    d3 = SwissDict((1 => 2, "a" => "b"))
    @test d == d2 == d3
    @test typeof(d) == typeof(d2) == typeof(d3) == SwissDict{Any,Any}
end

@testset "type of SwissDict constructed from varargs of Pairs" begin
    @test SwissDict(1=>1, 2=>2.0) isa SwissDict{Int,Real}
    @test SwissDict(1=>1, 2.0=>2) isa SwissDict{Real,Int}
    @test SwissDict(1=>1.0, 2.0=>2) isa SwissDict{Real,Real}

    for T in (Nothing, Missing)
        @test SwissDict(1=>1, 2=>T()) isa SwissDict{Int,Union{Int,T}}
        @test SwissDict(1=>T(), 2=>2) isa SwissDict{Int,Union{Int,T}}
        @test SwissDict(1=>1, T()=>2) isa SwissDict{Union{Int,T},Int}
        @test SwissDict(T()=>1, 2=>2) isa SwissDict{Union{Int,T},Int}
    end
end

@testset "equality" for eq in (isequal, ==)
    @test  eq(SwissDict(), SwissDict())
    @test  eq(SwissDict(1 => 1), SwissDict(1 => 1))
    @test !eq(SwissDict(1 => 1), SwissDict())
    @test !eq(SwissDict(1 => 1), SwissDict(1 => 2))
    @test !eq(SwissDict(1 => 1), SwissDict(2 => 1))

    # Generate some data to populate dicts to be compared
    data_in = [ (rand(1:1000), randstring(2)) for _ in 1:1001 ]

    # Populate the first dict
    d1 = SwissDict{Int, AbstractString}()
    for (k, v) in data_in
        d1[k] = v
    end
    data_in = collect(d1)
    # shuffle the data
    for i in 1:length(data_in)
        j = rand(1:length(data_in))
        data_in[i], data_in[j] = data_in[j], data_in[i]
    end
    # Inserting data in different (shuffled) order should result in
    # equivalent dict.
    d2 = SwissDict{Int, AbstractString}()
    for (k, v) in data_in
        d2[k] = v
    end

    @test eq(d1, d2)
    d3 = copy(d2)
    d4 = copy(d2)
    # Removing an item gives different dict
    delete!(d1, data_in[rand(1:length(data_in))][1])
    @test !eq(d1, d2)
    # Changing a value gives different dict
    d3[data_in[rand(1:length(data_in))][1]] = randstring(3)
    !eq(d1, d3)
    # Adding a pair gives different dict
    d4[1001] = randstring(3)
    @test !eq(d1, d4)

    @test eq(SwissDict(), sizehint!(SwissDict(),96))

    # Dictionaries of different types
    @test !eq(SwissDict(1 => 2), SwissDict("dog" => "bone"))
    @test eq(SwissDict{Int,Int}(), SwissDict{AbstractString,AbstractString}())
end

@testset "equality special cases" begin
    @test SwissDict(1=>0.0) == SwissDict(1=>-0.0)
    @test !isequal(SwissDict(1=>0.0), SwissDict(1=>-0.0))

    @test SwissDict(0.0=>1) != SwissDict(-0.0=>1)
    @test !isequal(SwissDict(0.0=>1), SwissDict(-0.0=>1))

    @test SwissDict(1=>NaN) != SwissDict(1=>NaN)
    @test isequal(SwissDict(1=>NaN), SwissDict(1=>NaN))

    @test SwissDict(NaN=>1) == SwissDict(NaN=>1)
    @test isequal(SwissDict(NaN=>1), SwissDict(NaN=>1))

    @test ismissing(SwissDict(1=>missing) == SwissDict(1=>missing))
    @test isequal(SwissDict(1=>missing), SwissDict(1=>missing))

    @test SwissDict(missing=>1) == SwissDict(missing=>1)
    @test isequal(SwissDict(missing=>1), SwissDict(missing=>1))
end

@testset "get!" begin 
    f(x) = x^2
    d = SwissDict(8=>19)
    @test get!(d, 8, 5) == 19
    @test get!(d, 19, 2) == 2

    @test get!(d, 42) do  # d is updated with f(2)
        f(2)
    end == 4

    @test get!(d, 42) do  # d is not updated
        f(200)
    end == 4

    @test get(d, 13) do   # d is not updated
        f(4)
    end == 16

    @test d == SwissDict(8=>19, 19=>2, 42=>4)

    d1 = SwissDict{Int8, Char}()
    d1[1%Int8] = 'a'
    @test get!(d1, 1, 'b') == 'a'
    @test get!(d1, 2, 'c') == 'c'
end

@testset "push!" begin
    d = SwissDict()
    @test push!(d, 'a' => 1) === d
    @test d['a'] == 1
    @test push!(d, 'b' => 2, 'c' => 3) === d
    @test d['b'] == 2
    @test d['c'] == 3
    @test push!(d, 'd' => 4, 'e' => 5, 'f' => 6) === d
    @test d['d'] == 4
    @test d['e'] == 5
    @test d['f'] == 6
    @test length(d) == 6
end

@testset "pop!" begin
    d = SwissDict(1=>2, 3=>4)
    @test pop!(d, 1) == 2
    @test_throws KeyError pop!(d, 1)
    @test pop!(d, 1, 0) == 0
    @test pop!(d) == (3=>4)
    @test_throws ArgumentError pop!(d)
end

@testset "keys as a set" begin
    d = SwissDict(1=>2, 3=>4)
    @test keys(d) isa AbstractSet
    @test empty(keys(d)) isa AbstractSet
    let i = keys(d) ∩ Set([1,2])
        @test i isa AbstractSet
        @test i == Set([1])
    end
    @test Set(string(k) for k in keys(d)) == Set(["1","3"])
end

@testset "find" begin
    @test findall(isequal(1), SwissDict(:a=>1, :b=>2)) == [:a]
    @test sort(findall(isequal(1), SwissDict(:a=>1, :b=>1))) == [:a, :b]
    @test isempty(findall(isequal(1), SwissDict()))
    @test isempty(findall(isequal(1), SwissDict(:a=>2, :b=>3)))

    @test findfirst(isequal(1), SwissDict(:a=>1, :b=>2)) == :a
    @test findfirst(isequal(1), SwissDict(:a=>1, :b=>1, :c=>3)) in (:a, :b)
    @test findfirst(isequal(1), SwissDict()) === nothing
    @test findfirst(isequal(1), SwissDict(:a=>2, :b=>3)) === nothing
end

@testset "haskey" begin
    h = SwissDict(1=>2, 2=>3)
    @test haskey(h, 1) == true
    @test haskey(h, 2) == true
    @test haskey(h, 3) == false
    @test !haskey(h, "1")
end

@testset "getkey" begin
    h = SwissDict(1=>2, 3 => 6, 5=>10)
    @test getkey(h, 1, 7) == 1
    @test getkey(h, 4, 6) == 6
    @test getkey(h, "1", 8) == 8
end


@testset "ArgumentError" begin
    @test_throws ArgumentError SwissDict(0)
    @test_throws ArgumentError SwissDict([1])
    @test_throws ArgumentError SwissDict([(1,2),0])
end

@testset "empty tuple" begin
    h = SwissDict(())
    @test length(h) == 0
end

@testset "empty" begin
    h = SwissDict()
    for i=1:10000
        h[i] = i+1
    end
    prev_sz = length(h.keys)
    @test length(h) != 0
    empty!(h)
    @test length(h) == 0
    @test length(h.keys) == length(h.vals) == prev_sz
end
