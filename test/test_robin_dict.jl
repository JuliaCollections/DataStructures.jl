@testset "Constructors" begin
    h1 = RobinDict()
    @test length(h1) == 0
    @test isempty(h1) == true
    @test h1.idxfloor == 0
    @test length(h1.keys) == 16
    @test length(h1.vals) == 16
    @test length(h1.hashes) == 16
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

    let y = RobinDict{Any, Int}(3=>3, 5=>5, "8"=>8, 6=>6)
        pop!(y, "8")
        for k in keys(y)
            RobinDict{Int,Int}(y)
            @test k in [3, 5, 6]
        end
    end

    d = @inferred RobinDict(Pair(1,1), Pair(2,2), Pair(3,3))
    @test isa(d, RobinDict)
    @test d == RobinDict(1=>1, 2=>2, 3=>3)
    @test eltype(d) == Pair{Int,Int}
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

    h = RobinDict{Char, Int}()
    @test_throws KeyError h[0.01] 
end

@testset "Filter function" begin
    _d = RobinDict("a"=>0)
    @test isa([k for k in filter(x->length(x)==1, collect(keys(_d)))], Vector{String})

    h = RobinDict{Int, Int}()
    for i in 1:100
        h[i] = i
    end
    filter!(x->isodd(x.first), h)
    for i in 1:2:100
        @test h[i] == i
    end
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
    @test RobinDict(1=>1, 2=>2.0) isa RobinDict{Int,Real}
    @test RobinDict(1=>1, 2.0=>2) isa RobinDict{Real,Int}
    @test RobinDict(1=>1.0, 2.0=>2) isa RobinDict{Real,Real}

    for T in (Nothing, Missing)
        @test RobinDict(1=>1, 2=>T()) isa RobinDict{Int,Union{Int,T}}
        @test RobinDict(1=>T(), 2=>2) isa RobinDict{Int,Union{Int,T}}
        @test RobinDict(1=>1, T()=>2) isa RobinDict{Union{Int,T},Int}
        @test RobinDict(T()=>1, 2=>2) isa RobinDict{Union{Int,T},Int}
    end
end

@testset "equality" for eq in (isequal, ==)
    @test  eq(RobinDict(), RobinDict())
    @test  eq(RobinDict(1 => 1), RobinDict(1 => 1))
    @test !eq(RobinDict(1 => 1), RobinDict())
    @test !eq(RobinDict(1 => 1), RobinDict(1 => 2))
    @test !eq(RobinDict(1 => 1), RobinDict(2 => 1))

    # Generate some data to populate dicts to be compared
    data_in = [ (rand(1:1000), randstring(2)) for _ in 1:1001 ]

    # Populate the first dict
    d1 = RobinDict{Int, AbstractString}()
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
    d2 = RobinDict{Int, AbstractString}()
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

    @test eq(RobinDict(), sizehint!(RobinDict(),96))

    # Dictionaries of different types
    @test !eq(RobinDict(1 => 2), RobinDict("dog" => "bone"))
    @test eq(RobinDict{Int,Int}(), RobinDict{AbstractString,AbstractString}())
end

@testset "equality special cases" begin
    @test RobinDict(1=>0.0) == RobinDict(1=>-0.0)
    @test !isequal(RobinDict(1=>0.0), RobinDict(1=>-0.0))

    @test RobinDict(0.0=>1) != RobinDict(-0.0=>1)
    @test !isequal(RobinDict(0.0=>1), RobinDict(-0.0=>1))

    @test RobinDict(1=>NaN) != RobinDict(1=>NaN)
    @test isequal(RobinDict(1=>NaN), RobinDict(1=>NaN))

    @test RobinDict(NaN=>1) == RobinDict(NaN=>1)
    @test isequal(RobinDict(NaN=>1), RobinDict(NaN=>1))

    @test ismissing(RobinDict(1=>missing) == RobinDict(1=>missing))
    @test isequal(RobinDict(1=>missing), RobinDict(1=>missing))

    @test RobinDict(missing=>1) == RobinDict(missing=>1)
    @test isequal(RobinDict(missing=>1), RobinDict(missing=>1))
end

@testset "get!" begin
    f(x) = x^2
    d = RobinDict(8=>19)
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

    @test d == RobinDict(8=>19, 19=>2, 42=>4)
end

@testset "push!" begin
    d = RobinDict()
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
    d = RobinDict(1=>2, 3=>4)
    @test pop!(d, 1) == 2
    @test_throws KeyError pop!(d, 1)
    @test pop!(d, 1, 0) == 0
    @test pop!(d) == (3=>4)
    @test_throws ArgumentError pop!(d)
end

@testset "keys as a set" begin
    d = RobinDict(1=>2, 3=>4)
    @test keys(d) isa AbstractSet
    @test empty(keys(d)) isa AbstractSet
    let i = keys(d) ∩ Set([1,2])
        @test i isa AbstractSet
        @test i == Set([1])
    end
    @test Set(string(k) for k in keys(d)) == Set(["1","3"])
end

@testset "find" begin
    @test findall(isequal(1), RobinDict(:a=>1, :b=>2)) == [:a]
    @test sort(findall(isequal(1), RobinDict(:a=>1, :b=>1))) == [:a, :b]
    @test isempty(findall(isequal(1), RobinDict()))
    @test isempty(findall(isequal(1), RobinDict(:a=>2, :b=>3)))

    @test findfirst(isequal(1), RobinDict(:a=>1, :b=>2)) == :a
    @test findfirst(isequal(1), RobinDict(:a=>1, :b=>1, :c=>3)) in (:a, :b)
    @test findfirst(isequal(1), RobinDict()) === nothing
    @test findfirst(isequal(1), RobinDict(:a=>2, :b=>3)) === nothing
end

@testset "haskey" begin
    h = RobinDict(1=>2, 2=>3)
    @test haskey(h, 1) == true
    @test haskey(h, 2) == true
    @test haskey(h, 3) == false
    @test haskey(h, "1") == false
end

@testset "getkey" begin
    h = RobinDict(1=>2, 3 => 6, 5=>10)
    @test getkey(h, 1, 7) == 1
    @test getkey(h, 4, 6) == 6
    @test getkey(h, "1", 8) == 8
end

@testset "empty" begin
    h = RobinDict()
    for i=1:1000
        h[i] = i+1
    end
    length0 = length(h.hashes)
    empty!(h)
    @test h.count == 0
    @test h.idxfloor == 0
    @test length(h.hashes) == length(h.keys) == length(h.vals) == length0
    for i=-1000:1000
      @test !haskey(h, i)
    end
end

@testset "ArgumentError" begin
    @test_throws ArgumentError RobinDict(0)
    @test_throws ArgumentError RobinDict([1])
    @test_throws ArgumentError RobinDict([(1,2),0])
end

@testset "empty tuple" begin
    h = RobinDict(())
    @test length(h) == 0
end

@testset "merge" begin
    h1 = RobinDict("a" => 1, "b" => 2)
    h2 = RobinDict("c" => 3, "d" => 4)
    d = merge(h1, h2)
    @test isa(d, RobinDict{String, Int})
    @test length(d) == 4
    @test d["a"] == 1
    @test d["b"] == 2
    @test d["c"] == 3
    @test d["d"] == 4
end

@testset "merge with combine function" begin
    h1 = RobinDict("a" => 1, "b" => 2)
    h2 = RobinDict("b" => 3, "c" => 4)
    d = merge(+, h1, h2)
    @test isa(d, RobinDict{String, Int})
    @test d["b"] == 5
    @test d["a"] == 1
    @test d["c"] == 4
end

@testset "invariants" begin
    # Functions which are not exported, but are required for checking invariants
    hash_key(key) = (hash(key)%UInt32) | 0x80000000
    desired_index(hash, sz) = (hash & (sz - 1)) + 1
    isslotfilled(h::RobinDict, index) = (h.hashes[index] != 0)
    isslotempty(h::RobinDict, index) = (h.hashes[index] == 0)
    
    function calculate_distance(h::RobinDict{K, V}, index) where {K, V}
        @assert isslotfilled(h, index)
        sz = length(h.keys)
        @inbounds index_init = desired_index(h.hashes[index], sz)
        return (index - index_init + sz) & (sz - 1)
    end

    function get_idxfloor(h::RobinDict)
        @inbounds for i = 1:length(h.keys)
            if isslotfilled(h, i)
                return i
            end
        end
        return 0
    end

    h1 = RobinDict{Int, Int}()
    for i in 1:300
        h1[i] = i
    end

    for i in 1:length(h1.keys)
        if isslotfilled(h1, i)
            @test hash_key(h1.keys[i]) == h1.hashes[i]
        end
    end

    h2 = RobinDict{Float64, Float64}()
    for i in 1:300
        h2[rand()] = rand()
    end

    for i in 1:length(h2.keys)
        if isslotfilled(h2, i)
            @test hash_key(h2.keys[i]) == h2.hashes[i]
        end
    end

    h3 = RobinDict{String, Int}()
    for i in 1:300
        h3[randstring()] = i
    end

    for i in 1:length(h3.keys)
        if isslotfilled(h3, i)
            @test hash_key(h3.keys[i]) == h3.hashes[i]
        end
    end

    max_disp = 0
    function check_invariants(h::RobinDict)
        cnt = 0
        min_idx = 0
        sz = length(h.keys)
        for i=1:length(h.keys)
            isslotfilled(h, i) || continue
            (min_idx == 0) && (min_idx = i)
            @assert hash_key(h.keys[i]) == h.hashes[i]
            @assert (h.hashes[i] & 0x80000000) != 0
            cnt += 1
            @assert typeof(h.hashes[i]) == UInt32
            des_ind = desired_index(h.hashes[i], sz)
            pos_diff = 0
            if (i >= des_ind)
                pos_diff = i - des_ind
            else
                pos_diff = sz - des_ind + i
            end
            dist = calculate_distance(h, i)
            @assert dist == pos_diff
            max_disp = max(max_disp, dist)
            distlast = (i != 1) ? isslotfilled(h, i-1) ? calculate_distance(h, i-1) : 0 : isslotfilled(h, sz) ? calculate_distance(h, sz) : 0
            @assert dist <= distlast + 1
        end
        @assert h.idxfloor == min_idx
        @assert cnt == length(h)
    end

    h = RobinDict()
    for i = 1:10000
        h[i] = i+1
    end
    check_invariants(h)

    @testset "get_idxfloor" begin
        h = RobinDict()
        @test get_idxfloor(h) == 0

        h["a"] = 1
        h[2] = "b"
        @test h.idxfloor == get_idxfloor(h)
        pop!(h)
        @test h.idxfloor == get_idxfloor(h)
        pop!(h)
        @test h.idxfloor == get_idxfloor(h) == 0
    end
end
