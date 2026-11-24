@testset "WeakKeyIdDict" begin
    A = [1]
    B = [2]
    C = [3]

    # construction
    wkd = WeakKeyIdDict()
    wkd[A] = 2
    wkd[B] = 3
    wkd[C] = 4
    dd = convert(Dict{Any,Any},wkd)
    @test WeakKeyIdDict(dd) == wkd
    @test convert(WeakKeyIdDict{Any, Any}, dd) == wkd
    @test isa(WeakKeyIdDict(dd), WeakKeyIdDict{Any,Any})
    @test WeakKeyIdDict(A=>2, B=>3, C=>4) == wkd
    @test isa(WeakKeyIdDict(A=>2, B=>3, C=>4), WeakKeyIdDict{Array{Int,1},Int})
    @test WeakKeyIdDict(a=>i+1 for (i,a) in enumerate([A,B,C]) ) == wkd
    @test WeakKeyIdDict([(A,2), (B,3), (C,4)]) == wkd
    @test WeakKeyIdDict(Pair(A,2), Pair(B,3), Pair(C,4)) == wkd
    @test copy(wkd) == wkd

    @test length(wkd) == 3
    @test !isempty(wkd)
    res = pop!(wkd, C)
    @test res == 4
    @test C ∉ keys(wkd)
    @test 4 ∉ values(wkd)
    @test length(wkd) == 2
    @test !isempty(wkd)
    wkd = filter!( p -> p.first != B, wkd)
    @test B ∉ keys(wkd)
    @test 3 ∉ values(wkd)
    @test length(wkd) == 1
    @test WeakKeyIdDict(Pair(A, 2)) == wkd
    @test !isempty(wkd)

    wkd = empty!(wkd)
    @test wkd == empty(wkd)
    @test typeof(wkd) == typeof(empty(wkd))
    @test length(wkd) == 0
    @test isempty(wkd)
    @test isa(wkd, WeakKeyIdDict)

    @test_throws ArgumentError WeakKeyIdDict([1, 2, 3])

    # WeakKeyIdDict does not convert keys
    @test_throws ArgumentError WeakKeyIdDict{Int,Any}(5.0=>1)

    # WeakKeyIdDict hashes with object-id
    AA = copy(A)
    GC.@preserve A AA begin
        wkd = WeakKeyIdDict(A=>1, AA=>2)
        @test length(wkd)==2
        kk = collect(keys(wkd))
        @test kk[1]==kk[2]
        @test kk[1]!==kk[2]
    end

    # WeakKeyIdDict compares to other dicts:
    @test IdDict(A=>1)!=WeakKeyIdDict(A=>1)
    @test Dict(A=>1)==WeakKeyIdDict(A=>1)
    @test Dict(copy(A)=>1)!=WeakKeyIdDict(A=>1)

    # issue #26939
    d26939 = WeakKeyIdDict()
    d26939[big"1.0" + 1.1] = 1
    GC.gc() # make sure this doesn't segfault
end
