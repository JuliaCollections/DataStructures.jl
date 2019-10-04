import DataStructures: DefaultDictBase

@testset "DefaultDict" begin

    @testset "DefaultDictBase" begin
        #construction
        @test_throws ArgumentError DefaultDictBase()
        @test isa(DefaultDictBase(0.0), DefaultDictBase{Any, Any, Float64, Dict{Any, Any}})
        @test isa(DefaultDictBase(0.0, 1 => 1.0), DefaultDictBase{Int, Float64, Float64, Dict{Int, Float64}})
        @test isa(DefaultDictBase(0.0, [(1, 1.0)]), DefaultDictBase{Int, Float64, Float64, Dict{Int, Float64}})
        #@test isa(DefaultDictBase(0.0, Dict()), DefaultDictBase{Any, Any, Float64, Dict{Any, Any}}))

        ddb = DefaultDictBase{Int, Float64}(0.0)
        @test isa(ddb, DefaultDictBase{Int, Float64, Float64, Dict{Int,Float64}})
        @test isa(DefaultDictBase(1.0, ddb), DefaultDictBase{Int, Float64, Float64, Dict{Int,Float64}})

        @test isa(DefaultDictBase{Int, String}(String), DefaultDictBase{Int, String, typeof(String), Dict{Int, String}})
        @test isa(DefaultDictBase{Int, String}(String; passkey=true), DefaultDictBase{Int, String, typeof(String), Dict{Int, String}})
        @test isa(DefaultDictBase{Int, String}(String; passkey=false), DefaultDictBase{Int, String, typeof(String), Dict{Int, String}})
    end

    @testset "DefaultDict" begin
        @testset "construction" begin
            @test_throws ArgumentError DefaultDict()
            @test_throws ArgumentError DefaultDict(AbstractString, Int)
            @test_throws ArgumentError DefaultDict{AbstractString, Int}()

            @test isa(DefaultDict(0.0, 1 => 1.0), DefaultDict{Int, Float64, Float64})
        end

        @testset "Core Functionality" begin
            for F in [1, ()->1]
                # empty dictionary
                d = DefaultDict{Char, Int}(F)
                @test length(d) == 0
                @test isempty(d)
                @test d['c'] == 1
                @test setindex!(d, 10, 'd') === d
                @test !isempty(d)
                @test empty!(d) === d
                @test isempty(d)

                # access, modification
                @test (d['a'] += 1) == 2
                @test 'a' in keys(d)
                @test haskey(d, 'a')
                @test get(d, 'b', 0) == 0
                @test !('b' in keys(d))
                @test !haskey(d, 'b')
                @test pop!(d, 'a') == 2
                @test isempty(d)

                # pushing multiple pairs
                @test push!(d, 'c'=>3, 'd'=>4, 'e'=>5, 'f'=>6) === d
                empty!(d)

                # pushing multiple tuples
                @test push!(d, ('c',3), ('d',4), ('e',5), ('f',6)) === d
                empty!(d)

                @test sizehint!(d, 26) === d

                for c in 'a':'z'
                    d[c] = c-'a'+1
                end

                @test d['z'] == 26
                @test d['@'] == 1
                @test length(d) == 27
                @test delete!(d, '@') === d
                @test length(d) == 26

                for (k,v) in d
                    @test v == k-'a'+1
                end

                s = empty(d)
                @test typeof(s) === typeof(d)
                @test s.d.default == d.d.default

                @test sort(collect(keys(d))) == collect('a':'z')
                @test sort(collect(values(d))) == collect(1:26)
            end
        end

        @testset "From Dict" begin
            # Starting from an existing dictionary
            # Note: dictionary is copied upon construction
            e = Dict([('a',1), ('b',3), ('c',5)])
            f = DefaultDict(0, e)
            @test f['d'] == 0
            @test_throws KeyError e['d']
            e['e'] = 9
            @test e['e'] == 9
            @test f['e'] == 0
        end

        @testset "passkey" begin
            calls = 0
            g = DefaultDict{String, Int}(passkey=true) do key
                calls += 1
                return length(key)
            end
            @test g["foobar"] == 6
            @test calls == 1
            @test length(g) == 1
            @test g["baz"] == 3
            @test calls == 2
            @test length(g) == 2
            @test g["foobar"] == 6
            @test calls == 2
            @test length(g) == 2

            @testset "Incorrect Usage" begin
                bad_dds = [
                    DefaultDict{Int, Int}(k -> k, passkey=false),
                    DefaultDict{Int, Int}(() -> 3, passkey=true),
                ]
                for bad_dd in bad_dds
                    bad_dd[3] = 10
                    @test bad_dd[3] == 10
                    @test_throws MethodError bad_dd[234]
                end
            end
        end

        # Alternate constructor
        @test isa(DefaultDict(0.0), DefaultDict{Any, Any, Float64})
        @test isa(DefaultDict(0.0, [(1, 1.0)]), DefaultDict{Int, Float64, Float64})
    end

    @testset "DefaultOrderedDict" begin
        @testset "construction" begin
            @test_throws ArgumentError DefaultOrderedDict()
            @test_throws ArgumentError DefaultOrderedDict{AbstractString, Int}()
        end

        @testset "Core Functionality" begin
            for F in [1, ()->1]
                # empty dictionary
                d = DefaultOrderedDict{Char, Int}(F)
                @test length(d) == 0
                @test isempty(d)
                @test d['c'] == 1
                @test setindex!(d, 10, 'd') === d
                @test !isempty(d)
                @test empty!(d) === d
                @test isempty(d)

                # access, modification
                @test (d['a'] += 1) == 2
                @test 'a' in keys(d)
                @test haskey(d, 'a')
                @test get(d, 'b', 0) == 0
                @test !('b' in keys(d))
                @test !haskey(d, 'b')
                @test pop!(d, 'a') == 2
                @test isempty(d)

                # pushing multiple pairs
                @test push!(d, 'c'=>3, 'd'=>4, 'e'=>5, 'f'=>6) === d
                empty!(d)

                # pushing multiple tuples
                @test push!(d, ('c',3), ('d',4), ('e',5), ('f',6)) === d
                empty!(d)

                @test sizehint!(d, 26) === d

                for c in 'a':'z'
                    d[c] = c-'a'+1
                end

                @test d['z'] == 26
                @test d['@'] == 1
                @test length(d) == 27
                @test delete!(d, '@') === d
                @test length(d) == 26

                for (k,v) in d
                    @test v == k-'a'+1
                end

                @test collect(keys(d)) == collect('a':'z')
                @test collect(values(d)) == collect(1:26)

                s = empty(d)
                @test typeof(s) === typeof(d)
                @test s.d.default == d.d.default
            end
        end

        @testset "Alternate constructor" begin
            @test isa(DefaultOrderedDict(0.0), DefaultOrderedDict{Any, Any, Float64})
            @test isa(DefaultOrderedDict(0.0, [(1, 1.0)]), DefaultOrderedDict{Int, Float64, Float64})
        end

        @testset "issue #216" begin
            @test DataStructures.isordered(DefaultOrderedDict{Int, String})
        end

    end

end
