@testset "MultiDict" begin

    @testset "Constructors" begin
        KVS = ('a',[1])
        KV = ('a',1)
        @test isa(MultiDict(), MultiDict{Any,Any})
        @test isa(MultiDict(()), MultiDict{Any,Any})
        @test isa(MultiDict([KVS]), MultiDict{Char,Int})
        @test isa(MultiDict([KV]), MultiDict{Char,Int})
        @test isa(MultiDict([KV, KVS]), MultiDict{Char,Any})

        PVS = 1 => [1.0]
        PV = 1 => 1.0
        @test eltype(MultiDict{Char,Int}()) === Pair{Char,Vector{Int}}
        @test isa(MultiDict(PVS), MultiDict{Int,Array{Float64,1}})
        @test isa(MultiDict(PVS, PVS), MultiDict{Int,Array{Float64,1}})
        @test isa(MultiDict([PVS, PVS]), MultiDict{Int,Array{Float64,1}})
        @test isa(MultiDict(PV), MultiDict{Int,Float64})
        @test isa(MultiDict(PV, PV), MultiDict{Int,Float64})
        @test isa(MultiDict([PV, PV]), MultiDict{Int,Float64})
    end

    @testset "Core Functionality" begin
        # setindex!, getindex, length, isempty, empty!, in
        # copy, empty, get, haskey, getkey, iterate
        d = MultiDict{Char,Int}()

        @test length(d) == 0
        @test isempty(d)

        @test insert!(d, 'a', 1) == MultiDict{Char,Int}([('a', [1])])
        @test getindex(d, 'a') == [1]
        @test_throws MethodError insert!(d, 'a', [2,3]) == MultiDict{Char,Int}([('a', [1,2,3])])
        @test insert!(d, 'a', 2) == MultiDict{Char,Int}([('a', [1,2])])
        @test insert!(d, 'a', 3) == MultiDict{Char,Int}([('a', [1,2, 3])])
        @test getindex(d, 'a') == [1,2,3]

        @test_throws KeyError d['c'] == 1
        insert!(d, 'c', 1)

        # order changed from v0.4 to v0.5
        @test collect(keys(d)) == ['c', 'a'] || collect(keys(d)) == ['a', 'c']
        @test collect(values(d)) == Array{Int,1}[[1],[1,2,3]] || collect(values(d)) == Array{Int,1}[[1,2,3], [1]]

        @test get(d, 'a', 0) == [1,2,3]
        @test get(d, 'b', 0) == 0

        @test haskey(d, 'a')
        @test !haskey(d, 'b')
        @test getkey(d, 'a', 0) == 'a'
        @test getkey(d, 'b', 0) == 0

        @test copy(d) == d
        @test empty(d) == MultiDict{Char,Int}()

        @testset "order changed from v0.4 to v0.5" begin
            dict = [kv for kv in d]
            @test  dict == [Pair('c', [1]), Pair('a', [1,2,3])] ||
                    dict == [Pair('a', [1,2,3]), Pair('c', [1])]
        end

        @testset "in" begin
            @test in(('c', 1), d)
            @test in(('a', 1), d)
            @test in(('a', 2), d)
        end

        @testset "isempty / empty!" begin
            @test !isempty(d)
            empty!(d)
            @test isempty(d)
        end

        @testset "pop!" begin
            d = MultiDict{Char,Int}([('a', [1,2,3]), ('c', [1])])
            @test_throws KeyError pop!(d, 'b')
            @test pop!(d, 'a') == 3
            @test pop!(d, 'a') == 2
            @test pop!(d, 'a') == 1
            @test !haskey(d, 'a')
            @test pop!(d, 'b', 0) == 0
        end
    end

    @testset "delete!" begin
        d = MultiDict{Char,Int}([('a', [1,2,3]), ('c', [1])])
        @test delete!(d, 'b') == d
        @test delete!(d, 'a') == MultiDict{Char,Int}([('c', [1])])
    end

    @testset "setindex!" begin
        d = MultiDict{Char,Int}()
        @test insert!(d, 'a', 1) == MultiDict{Char,Int}([('a', [1])])
        @test insert!(d, 'a', 1) == MultiDict{Char,Int}([('a', [1, 1])])
    end

    @testset "push!" begin
        d = MultiDict{Char,Int}()
        @test push!(d, ('a',1)) == MultiDict{Char,Int}([('a', [1])])
        @test push!(d, ('a',1)) == MultiDict{Char,Int}([('a', [1,1])])
        empty!(d)
        @test push!(d,'a'=>1) == MultiDict{Char,Int}([('a', [1])])
        @test push!(d, 'a'=>1) == MultiDict{Char,Int}([('a', [1,1])])

        @testset "get!" begin
            @test get!(d, 'a', []) == [1,1]
            @test get!(d, 'b', []) == Int[]
            @test get!(d, 'c', [1]) == [1]
            @test_throws MethodError get!(d, 'd', 1)
        end
    end

    @testset "special functions: count, enumerateall" begin
        #not appending arrays to one array, using array of arrays
        d = MultiDict{Char,Array{Int,1}}()
        @test count(d) == 0
        for i in 1:15
            insert!(d, rand('a':'f'), rand()>0.5 ? [rand(1:10)] : rand(1:10, rand(1:3)))
        end
        @test 15 <= count(d) <=45
        @test size(d) == (length(d), count(d))

        #= --- broken phlavenk ----
        allvals = [kv for kv in enumerateall(d)]
        @test length(allvals) == count(d)
        @test all(kv->in(kv,d), enumerateall(d))

        # @test length(d) == 15
        # @test length(values(d)) == 15
        # @test length(keys(d)) <= 6
        --- broken phlavenk ---- =#
    end

end # @testset MultiDict
