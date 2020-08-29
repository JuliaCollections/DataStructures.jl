# These are the tests for deprecated features, they should be deleted along with them

@testset "Trie: path iterator" begin
    t = Trie{Int}()
    t["rob"] = 27
    t["roger"] = 52
    t["kevin"] = Int8(11)
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