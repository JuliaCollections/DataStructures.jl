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

@testset "top" begin
    hh = BinaryMinHeap{Float64}([1,2,3])
    @test top(hh) == 1
end

function test_reverse_iter(it::T) where T
    arr = [i for i in it]
    index = length(arr)
    for i in reverse_iter(it)
        @test arr[index] == i
        index -= 1
    end

    @test reverse(arr) == [i for i in reverse_iter(it)]
end
@testset "reverse_iter" begin
    @testset "Queue" begin
        q = Queue{Int}(); enqueue!(q, 1); enqueue!(q, 2)
        test_reverse_iter(q)
    end
    @testset "Stack" begin
        s = Stack{Int}(); push!(s, 1); push!(s, 2)
        test_reverse_iter(s)
    end
end
