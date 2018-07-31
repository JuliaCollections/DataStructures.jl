using DataStructures, Test

@testset "OrderedDict" begin

    @testset "Constructors" begin
        @test isa(OrderedDict(), OrderedDict{Any,Any})
        @test isa(OrderedDict([(1,2.0)]), OrderedDict{Int,Float64})
        @test isa(OrderedDict([("a",1),("b",2)]), OrderedDict{String,Int})
        @test isa(OrderedDict(Pair(1, 1.0)), OrderedDict{Int,Float64})
        @test isa(OrderedDict(Pair(1, 1.0), Pair(2, 2.0)), OrderedDict{Int,Float64})
        @test isa(OrderedDict(Pair(1, 1.0), Pair(2, 2.0), Pair(3, 3.0)), OrderedDict{Int,Float64})
    end

    @testset "empty dictionary" begin
        d = OrderedDict{Char, Int}()
        @test length(d) == 0
        @test isempty(d)
        @test_throws KeyError d['c'] == 1
        d['c'] = 1
        @test !isempty(d)
        @test_throws KeyError d[0.01]
        @test isempty(empty(d))
        empty!(d)
        @test isempty(d)

        # access, modification
        for c in 'a':'z'
            d[c] = c - 'a' + 1
        end

        @test (d['a'] += 1) == 2
        @test 'a' in keys(d)
        @test haskey(d, 'a')
        @test get(d, 'B', 0) == 0
        @test !('B' in keys(d))
        @test !haskey(d, 'B')
        @test pop!(d, 'a') == 2

        @test collect(keys(d)) == collect('b':'z')
        @test collect(values(d)) == collect(2:26)
        @test collect(d) == [Pair(a,i) for (a,i) in zip('b':'z', 2:26)]
    end

    @testset "Issue #60" begin
        od60 = OrderedDict{Int,Int}()
        od60[1] = 2

        ranges = [2:5, 6:9, 10:13]
        for range in ranges
            for i = range
                od60[i] = i+1
            end
            for i = range
                delete!( od60, i )
            end
        end
        od60[14]=15

        @test od60[14] == 15
    end


    ##############################
    # Copied and modified from Base/test/dict.jl

    # OrderedDict

    @testset "OrderedDict{Int,Int}" begin
        h = OrderedDict{Int,Int}()
        for i=1:10000
            h[i] = i+1
        end

        @test collect(h) == [Pair(x,y) for (x,y) in zip(1:10000, 2:10001)]

        for i=1:2:10000
            delete!(h, i)
        end
        for i=1:2:10000
            h[i] = i+1
        end

        for i=1:10000
            @test h[i]==i+1
        end

        for i=1:10000
            delete!(h, i)
        end
        @test isempty(h)

        h[77] = 100
        @test h[77]==100

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
            @test h[i]==i+1
        end

        for i=10000:20000
            @test h[i]==i+1
        end
    end

    @testset "OrderedDict{Any,Any}" begin
        h = OrderedDict{Any,Any}([("a", 3)])
        @test h["a"] == 3
        h["a","b"] = 4
        @test h["a","b"] == h[("a","b")] == 4
        h["a","b","c"] = 4
        @test h["a","b","c"] == h[("a","b","c")] == 4
    end

    @testset "KeyError" begin
        z = OrderedDict()
        get_KeyError = false
        try
            z["a"]
        catch _e123_
            get_KeyError = isa(_e123_, KeyError)
        end
        @test get_KeyError
    end

    @testset "filter" begin
        _d = OrderedDict([("a", 0)])
        v = [k for k in filter(x->length(x)==1, collect(keys(_d)))]
        @test isa(v, Vector{String})
    end

    @testset "from tuple/vector/pairs/tuple of pair 1" begin
        d = OrderedDict(((1, 2), (3, 4)))
        d2 = OrderedDict([(1, 2), (3, 4)])
        d3 = OrderedDict(1 => 2, 3 => 4)
        d4 = OrderedDict((1 => 2, 3 => 4))

        @test d[1] === 2
        @test d[3] === 4

        @test d == d2 == d3 == d4
        @test isa(d, OrderedDict{Int,Int})
        @test isa(d2, OrderedDict{Int,Int})
        @test isa(d3, OrderedDict{Int,Int})
        @test isa(d4, OrderedDict{Int,Int})
    end

    @testset "from tuple/vector/pairs/tuple of pair 2" begin
        d = OrderedDict(((1, 2), (3, "b")))
        d2 = OrderedDict([(1, 2), (3, "b")])
        d3 = OrderedDict(1 => 2, 3 => "b")
        d4 = OrderedDict((1 => 2, 3 => "b"))

        @test d2[1] === 2
        @test d2[3] == "b"

        ## TODO: tuple of tuples doesn't work for mixed tuple types
        # @test d == d2 == d3 == d4
        # @test isa(d, OrderedDict{Int,Any})
        @test d2 == d3 == d4
        @test isa(d2, OrderedDict{Int,Any})
        @test isa(d3, OrderedDict{Int,Any})
        @test isa(d4, OrderedDict{Int,Any})
    end

    @testset "from tuple/vector/pairs/tuple of pair 3" begin
        d = OrderedDict(((1, 2), ("a", 4)))
        d2 = OrderedDict([(1, 2), ("a", 4)])
        d3 = OrderedDict(1 => 2, "a" => 4)
        d4 = OrderedDict((1 => 2, "a" => 4))

        @test d2[1] === 2
        @test d2["a"] === 4

        ## TODO: tuple of tuples doesn't work for mixed tuple types
        # @test d == d2 == d3 == d4
        @test d2 == d3 == d4
        # @test isa(d, OrderedDict{Any,Int})
        @test isa(d2, OrderedDict{Any,Int})
        @test isa(d3, OrderedDict{Any,Int})
        @test isa(d4, OrderedDict{Any,Int})
    end

    @testset "from tuple/vector/pairs/tuple of pair 4" begin
        d = OrderedDict(((1, 2), ("a", "b")))
        d2 = OrderedDict([(1, 2), ("a", "b")])
        d3 = OrderedDict(1 => 2, "a" => "b")
        d4 = OrderedDict((1 => 2, "a" => "b"))

        @test d[1] === 2
        @test d["a"] == "b"

        @test d == d2 == d3 == d4
        @test isa(d, OrderedDict{Any,Any})
        @test isa(d2, OrderedDict{Any,Any})
        @test isa(d3, OrderedDict{Any,Any})
        @test isa(d4, OrderedDict{Any,Any})
    end

    @testset "first" begin
        @test_throws ArgumentError first(OrderedDict())
        @test first(OrderedDict([(:f, 2)])) == Pair(:f,2)
    end

    @testset "Issue #1821" begin
        d = OrderedDict{String, Vector{Int}}()
        d["a"] = [1, 2]
        @test_throws MethodError d["b"] = 1
        @test isa(repr(d), AbstractString)  # check that printable without error
    end

    @testset "Issue #2344" begin
        bestkey(d, key) = key
        bestkey(d::AbstractDict{K,V}, key) where {K<:AbstractString,V} = string(key)
        bar(x) = bestkey(x, :y)
        @test bar(OrderedDict([(:x, [1,2,5])])) == :y
        @test bar(OrderedDict([("x", [1,2,5])])) == "y"
    end

    @testset "isequal" begin
        @test  isequal(OrderedDict(), OrderedDict())
        @test  isequal(OrderedDict([(1, 1)]), OrderedDict([(1, 1)]))
        @test !isequal(OrderedDict([(1, 1)]), OrderedDict())
        @test !isequal(OrderedDict([(1, 1)]), OrderedDict([(1, 2)]))
        @test !isequal(OrderedDict([(1, 1)]), OrderedDict([(2, 1)]))

        @test isequal(OrderedDict(), sizehint!(OrderedDict(),96))

        # Here is what currently happens when dictionaries of different types
        # are compared. This is not necessarily desirable. These tests are
        # descriptive rather than proscriptive.
        @test !isequal(OrderedDict([(1, 2)]), OrderedDict([("dog", "bone")]))
        @test isequal(OrderedDict{Int,Int}(), OrderedDict{AbstractString,AbstractString}())
    end

    @testset "data_in" begin
        # Generate some data to populate dicts to be compared
        data_in = [ (rand(1:1000), randstring(2)) for _ in 1:1001 ]

        # Populate the first dict
        d1 = OrderedDict{Int, String}()
        for (k,v) in data_in
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
        d2 = OrderedDict{Int, AbstractString}()
        for (k,v) in data_in
            d2[k] = v
        end

        @test  isequal(d1, d2)
        d3 = copy(d2)
        d4 = copy(d2)
        # Removing an item gives different dict
        delete!(d1, data_in[rand(1:length(data_in))][1])
        @test !isequal(d1, d2)
        # Changing a value gives different dict
        d3[data_in[rand(1:length(data_in))][1]] = randstring(3)
        !isequal(d1, d3)
        # Adding a pair gives different dict
        d4[1001] = randstring(3)
        @test !isequal(d1, d4)
    end

    @testset "get!" begin
        # get! (get with default values assigned to the given location)
        f(x) = x^2
        d = OrderedDict(8 => 19)

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

        @test d == OrderedDict(8=>19, 19=>2, 42=>4)
    end

    @testset "Issue #5886" begin
        d5886 = OrderedDict()
        for k5886 in 1:11
            d5886[k5886] = 1
        end
        for k5886 in keys(d5886)
            # undefined ref if not fixed
            d5886[k5886] += 1
        end
    end

    @testset "Issue #216" begin
        @test DataStructures.isordered(OrderedDict{Int, String})
        @test !DataStructures.isordered(Dict{Int, String})
    end

    @testset "Test merging" begin
        a = OrderedDict("foo"  => 0.0, "bar" => 42.0)
        b = OrderedDict("フー" => 17, "バー" => 4711)
        @test isa(merge(a, b), OrderedDict{String,Float64})
    end

    @testset "Issue #9295" begin
        d = OrderedDict()
        @test push!(d, 'a'=> 1) === d
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

    @testset "Serialization" begin
        s = IOBuffer()
        od = OrderedDict{Char,Int64}()
        for c in 'a':'e'
            od[c] = c-'a'+1
        end
        serialize(s, od)
        seek(s, 0)
        dd = deserialize(s)
        @test isa(dd, DataStructures.OrderedDict{Char,Int64})
        @test dd == od
        close(s)
    end

    @testset "Issue #148" begin
        d148 = OrderedDict(
                    :gps => [],
                    :direction => 1:8,
                    :weather => 1:10
            )
        
        d148_2 = OrderedDict(
            :time => 1:10,
            :features => OrderedDict(
                :gps => 1:5,
                :direction => 1:8,
                :weather => 1:10
            )
        )
    end

    @testset "Issue #400" begin
        @test filter(p->first(p) > 1, OrderedDict(1=>2, 3=>4)) isa OrderedDict
    end

end # @teestset OrderedDict
