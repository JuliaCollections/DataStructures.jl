using DataStructures: IntSemiToken

# These are the tests for deprecated features, they should be deleted along with them

@testset "Trie: path iterator" begin
    t = Trie{Char,Int}()
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
        q = Queue{Int}(); push!(q, 1); push!(q, 2)
        test_reverse_iter(q)
    end
    @testset "Stack" begin
        s = Stack{Int}(); push!(s, 1); push!(s, 2)
        test_reverse_iter(s)
    end
end

@testset "Queue enqueue! dequeue!" begin
    s = Queue{Int}(5)
    n = 100

    @test length(s) == 0
    @test eltype(s) == Int
    @test eltype(typeof(s)) == Int
    @test isempty(s)
    @test_throws ArgumentError first(s)
    @test_throws ArgumentError last(s)
    @test_throws ArgumentError dequeue!(s)

    for i = 1 : n
        enqueue!(s, i)
        @test first(s) == 1
        @test last(s) == i
        @test !isempty(s)
        @test length(s) == i
    end

    for i = 1 : n
        x = dequeue!(s)
        @test x == i
        if i < n
            @test first(s) == i + 1
            @test last(s) == n
        else
            @test_throws ArgumentError first(s)
            @test_throws ArgumentError last(s)
        end
        @test isempty(s) == (i == n)
        @test length(s) == n - i
    end
end

@testset "PriorityQueue enqueue! dequeue!" begin
    s = PriorityQueue{Int,Int}()
    n = 100

    @test length(s) == 0
    @test isempty(s)
    @test_throws BoundsError first(s)
    @test_throws BoundsError dequeue!(s)

    for i = 1 : n
        enqueue!(s, i=>i)
        @test first(s) == (1=>1)
        @test !isempty(s)
        @test length(s) == i
    end

    for i = 1 : n
        x = dequeue!(s)
        @test x == i
        if i < n
            @test first(s) == (i+1 => i+1)
        else
            @test_throws BoundsError first(s)
        end
        @test isempty(s) == (i == n)
        @test length(s) == n - i
    end
end

@testset "peek" begin
    pq = PriorityQueue{Int,Int}()
    push!(pq, 1 => 1)
    push!(pq, 2 => 2)
    @test peek(pq) == (1=>1)
    pq = PriorityQueue{Int,Int}()
    push!(pq, 2 => 2)
    push!(pq, 1 => 1)
    @test peek(pq) == (1=>1)
end

@testset "insert!" begin
    # issues 479 and 767: deprecate insert! (in favor of push_return_semitoken!)
    # deprecate startof in favor of firstindex
    # deprecate endof in favor of lastindex
    s = SortedDict{Int,String}();
    @test isa(insert!(s, 5, "hello"), Tuple{Bool, IntSemiToken})
    s2 = SortedMultiDict{Int,String}();
    @test isa(insert!(s2, 5, "hello"), IntSemiToken)
    s3 = SortedSet{Int}()
    @test isa(insert!(s3, 5), Tuple{Bool, IntSemiToken})
    s4 = SortedDict{Int,String}(3=>"o", 4=>"p")
    @test deref_key((s4,startof(s4))) == 3
    @test deref_key((s4,endof(s4))) == 4
end
