# This was formerly a part of Julia. License is MIT: http://julialang.org/license

import Base.Order.Reverse


@testset "PriorityQueue" begin

# Test dequeing in sorted order.
function test_issorted!(pq::PriorityQueue, priorities, rev=false)
    last = dequeue!(pq)
    while !isempty(pq)
        value = dequeue!(pq)
        if !rev
            @test priorities[last] <= priorities[value]
        else
            @test priorities[value] <= priorities[last]
        end
        value = last
    end
end

function test_isrequested!(pq::PriorityQueue, keys)
    i = 0
    while !isempty(pq)
        krqst =  keys[i+=1]
        krcvd = dequeue!(pq, krqst)
        @test krcvd == krqst
    end
end

@testset "Constructors" begin
    pmax = 1000
    n = 10000
    r = rand(1:pmax, n)
    priorities = Dict(zip(1:n, r))

    # building from a dict
    pq1 = PriorityQueue(priorities)
    test_issorted!(pq1, priorities)

    pq2 = PriorityQueue(priorities)
    test_isrequested!(pq2, 1:n)

    # building from two lists (deprecated)
    ks, vs = 1:n, rand(1:pmax, n)
    println("\nThe following warning is expected:")
    pq3 = PriorityQueue(ks,vs)

    # building from two lists of different sizes - throws an error
    ks, vs = 1:n+1, rand(1:pmax, n)
    println("\nThe following warning is expected:")
    @test_throws ArgumentError PriorityQueue(ks, vs)

    # building from Dict
    priorities = Dict(zip(ks, vs))
    pq4 = PriorityQueue(priorities)
    test_issorted!(pq4, priorities)

    # parameterized constructor tests
    pq5 = PriorityQueue{Int,Int}()
    for (k,v) in priorities
        pq5[k] = v
    end
    test_issorted!(pq5, priorities)

    # parameterized constructor tests
    pq6 = PriorityQueue{Int,Int}(priorities)
    test_issorted!(pq6, priorities)

    # parameterized constructor tests
    pq7 = PriorityQueue{Int,Int}(Reverse, priorities)
    test_issorted!(pq7, priorities, true)

    # parameterized constructor tests
    pq8 = PriorityQueue{Int,Int}(Reverse)
    for (k,v) in priorities
        pq8[k] = v
    end
    test_issorted!(pq8, priorities, true)

    # construction from pairs
    pq9 = PriorityQueue('a'=>1, 'b'=>2)
    @test peek(pq9) == ('a'=>1)

    pq10 = PriorityQueue(Reverse, 'a'=>1, 'b'=>2)
    @test peek(pq10) == ('b'=>2)

    pq11 = PriorityQueue(Pair{Char}['a'=>1,'b'=>2])
    @test peek(pq11) == ('a'=>1)

    # duplicate key => ArgumentError
    @test_throws ArgumentError PriorityQueue('a'=>1, 'a'=>2)

    # Not a pair/tuple => ArguentError
    @test_throws ArgumentError PriorityQueue(['a'])
    @test_throws ArgumentError PriorityQueue(Reverse, ['a'])
    @test_throws ArgumentError PriorityQueue{Char,Int}(Base.Order.Reverse, ['a'])

    # Silly test
    @test_throws ArgumentError PriorityQueue(Reverse, Reverse)

end

@testset "PriorityQueueMethods" begin
    pq1 = PriorityQueue('a'=>1, 'b'=>2)
    @test peek(pq1) == ('a'=>1)
    @test get(pq1, 'a', 0) == 1
    @test get(pq1, 'c', 0) == 0
    @test dequeue!(pq1) == 'a'
    @test dequeue!(pq1) == 'b'

    pmax = 1000
    n = 10000
    ks, vs = 1:n, rand(1:pmax, n)
    priorities = Dict(zip(ks, vs))

    # peek
    pq1 = PriorityQueue(priorities)
    lowpri = findmin(vs)
    @test peek(pq1)[2] == pq1[ks[lowpri[2]]]

    #enqueue error throw
    ks, vs = 1:n, rand(1:pmax, n)
    pq = PriorityQueue(zip(ks, vs))
    @test_throws ArgumentError enqueue!(pq, 1, 10)

    # Iteration

    pq = PriorityQueue(priorities)
    pq2 = PriorityQueue()
    for kv in pq
        enqueue!(pq2, kv)
    end
    @test pq == pq2

    # enqueing pairs via enqueue!
    pq = PriorityQueue()
    for kv in priorities
        enqueue!(pq, kv)
    end
    test_issorted!(pq, priorities)

    # enqueing values via enqueue!
    pq = PriorityQueue()
    for (k, v) in priorities
        enqueue!(pq, k, v)
    end
    test_issorted!(pq, priorities)

    # enqueing via assign
    pq = PriorityQueue()
    for (k, v) in priorities
        pq[k] = v
    end
    test_issorted!(pq, priorities)

    # changing priorities
    pq = PriorityQueue()
    for (k, v) in priorities
        pq[k] = v
    end

    for _ in 1:n
        k = rand(1:n)
        v = rand(1:pmax)
        pq[k] = v
        priorities[k] = v
    end

    test_issorted!(pq, priorities)

    # dequeuing
    pq = PriorityQueue(priorities)
    @test_throws KeyError dequeue!(pq, 0)

    @test 10 == dequeue!(pq, 10)
    while !isempty(pq)
        @test 10 != dequeue!(pq)
    end

    priorities2 = Dict(zip('a':'e', 5:-1:1))
    pq = PriorityQueue(priorities2)
    @test_throws KeyError dequeue_pair!(pq, 'g')
    @test dequeue_pair!(pq) == ('e'=> 1)
    @test dequeue_pair!(pq, 'b') == ('b'=>4)
    @test length(pq) == 3
end

@testset "LowLevelHeapOperations" begin
    pmax = 1000
    n = 10000
    r = rand(1:pmax, n)
    priorities = Dict(zip(1:n, r))

    # low level heap operations
    xs = heapify!([v for v in values(priorities)])
    @test issorted([heappop!(xs) for _ in length(priorities)])

    xs = heapify(10:-1:1)
    @test issorted([heappop!(xs) for _ in 1:10])

    xs = Vector{Int}()
    for priority in values(priorities)
        heappush!(xs, priority)
    end
    @test issorted([heappop!(xs) for _ in length(priorities)])

    @test isheap([1, 2, 3], Base.Order.Forward)
    @test !isheap([1, 2, 3], Base.Order.Reverse)
end

end # @testset "PriorityQueue"
