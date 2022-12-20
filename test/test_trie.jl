@testset "Trie" begin
    @testset "Core Functionality" begin
        t = Trie{Char,Int}()
        t["amy"] = 56
        t["ann"] = 15
        t["emma"] = 30
        t["rob"] = 27
        t["roger"] = 52
        t["kevin"] = Int8(11)

        @test haskey(t, "roger")
        @test get(t,"rob",nothing) == 27
        @test sort(keys(t)) == ["amy", "ann", "emma", "kevin", "rob", "roger"]
        @test t["rob"] == 27
        @test sort(keys_with_prefix(t,"ro")) == ["rob", "roger"]
    end

    @testset "Constructors" begin
        ks = ["amy", "ann", "emma", "rob", "roger"]
        vs = [56, 15, 30, 27, 52]
        kvs = collect(zip(ks, vs))
        @test isa(Trie(ks, vs), Trie{Char,Int})
        @test isa(Trie(kvs), Trie{Char,Int})
        @test isa(Trie(Dict(kvs)), Trie{Char,Int})
        @test isa(Trie(ks), Trie{Char,Nothing})
    end

    @testset "partial_path iterator" begin
        t = Trie{Char,Int}()
        t["rob"] = 27
        t["roger"] = 52
        t["kevin"] = Int8(11)
        t0 = t
        t1 = t0.children['r']
        t2 = t1.children['o']
        t3 = t2.children['b']
        @test collect(partial_path(t, "b")) == [t0]
        @test collect(partial_path(t, "rob")) == [t0, t1, t2, t3]
        @test collect(partial_path(t, "robb")) == [t0, t1, t2, t3]
        @test collect(partial_path(t, "ro")) == [t0, t1, t2]
        @test collect(partial_path(t, "roa")) == [t0, t1, t2]
    end

    @testset "partial_path iterator non-ascii" begin
        t = Trie(["東京都"])
        t0 = t
        t1 = t0.children['東']
        t2 = t1.children['京']
        t3 = t2.children['都']
        @test collect(partial_path(t, "西")) == [t0]
        @test collect(partial_path(t, "東京都")) == [t0, t1, t2, t3]
        @test collect(partial_path(t, "東京都渋谷区")) == [t0, t1, t2, t3]
        @test collect(partial_path(t, "東京")) == [t0, t1, t2]
        @test collect(partial_path(t, "東京スカイツリー")) == [t0, t1, t2]
    end

    @testset "find_prefixes" begin
        t = Trie(["A", "ABC", "ABD", "BCD"])
        prefixes = find_prefixes(t, "ABCDE")
        @test prefixes == ["A", "ABC"]
    end

    @testset "find_prefixes non-ascii" begin
        t = Trie(["東京都", "東京都渋谷区", "東京都新宿区"])
        prefixes = find_prefixes(t, "東京都渋谷区東")
        @test prefixes == ["東京都", "東京都渋谷区"]
    end

    @testset "non-string indexing" begin
        t = Trie{Int,Int}()
        t[[1,2,3,4]] = 1
        t[[1,2]] = 2
        @test haskey(t, [1,2])
        @test get(t, [1,2], nothing) == 2
        st = subtrie(t, [1,2,3])
        @test keys(st) == [[4]]
        @test st[[4]] == 1
        @test find_prefixes(t, [1,2,3,5]) == [[1,2]]
        @test find_prefixes(t, 1:3) == [1:2]
    end
end # @testset Trie
