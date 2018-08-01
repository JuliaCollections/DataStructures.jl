@testset "Trie" begin

    t = Trie{Int}()

    @testset "Core Functionality" begin
        t["amy"] = 56
        t["ann"] = 15
        t["emma"] = 30
        t["rob"] = 27
        t["roger"] = 52

        @test haskey(t, "roger")
        @test get(t,"rob",nothing) == 27
        @test sort(keys(t)) == ["amy", "ann", "emma", "rob", "roger"]
        @test t["rob"] == 27
        @test sort(keys_with_prefix(t,"ro")) == ["rob", "roger"]
    end

    @testset "Constructors" begin
        ks = ["amy", "ann", "emma", "rob", "roger"]
        vs = [56, 15, 30, 27, 52]
        kvs = collect(zip(ks, vs))
        @test isa(Trie(ks, vs), Trie{Int})
        @test isa(Trie(kvs), Trie{Int})
        @test isa(Trie(Dict(kvs)), Trie{Int})
        @test isa(Trie(ks), Trie{Nothing})
    end

    @testset "path iterator" begin
        t0 = t
        t1 = t0.children['r']
        t2 = t1.children['o']
        t3 = t2.children['b']
        @test collect(path(t, "b")) == [t0]
        @test collect(path(t, "rob")) == [t0, t1, t2, t3]
        @test collect(path(t, "robb")) == [t0, t1, t2, t3]
        @test collect(path(t, "ro")) == [t0, t1, t2]
        @test collect(path(t, "roa")) == [t0, t1, t2]
    end

end # @testset Trie
