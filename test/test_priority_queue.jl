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

        ks, vs = 1:n+1, rand(1:pmax, n)

        @testset "building from Dict" begin
            pq1 = PriorityQueue(priorities)
            test_issorted!(pq1, priorities)

            pq2 = PriorityQueue(priorities)
            test_isrequested!(pq2, 1:n)

            priorities = Dict(zip(ks, vs))
            pq4 = PriorityQueue(priorities)
            test_issorted!(pq4, priorities)
        end

        @testset "parameterized constructor tests pq5" begin
            pq5 = PriorityQueue{Int,Int}()
            for (k,v) in priorities
                pq5[k] = v
            end
            test_issorted!(pq5, priorities)
        end

        @testset "parameterized constructor tests pq6" begin
            pq6 = PriorityQueue{Int,Int}(priorities)
            test_issorted!(pq6, priorities)
        end

        @testset "parameterized constructor tests pq7" begin
            pq7 = PriorityQueue{Int,Int}(Reverse, priorities)
            test_issorted!(pq7, priorities, true)
        end

        @testset "parameterized constructor tests pq8" begin
            pq8 = PriorityQueue{Int,Int}(Reverse)
            for (k,v) in priorities
                pq8[k] = v
            end
            test_issorted!(pq8, priorities, true)
        end

        @testset "construction from pairs" begin
            @testset "pq9" begin
                pq9 = PriorityQueue('a'=>1, 'b'=>2)
                @test peek(pq9) == ('a'=>1)
            end

            @testset "pq10" begin
                pq10 = PriorityQueue(Reverse, 'a'=>1, 'b'=>2)
                @test peek(pq10) == ('b'=>2)
            end

            @testset "pq11" begin
                pq11 = PriorityQueue(Pair{Char}['a'=>1,'b'=>2])
                @test peek(pq11) == ('a'=>1)
            end
        end

        @testset "duplicate key => ArgumentError" begin
            @test_throws ArgumentError PriorityQueue('a'=>1, 'a'=>2)
        end

        @testset "Not a pair/tuple => ArguentError" begin
            @test_throws ArgumentError PriorityQueue(['a'])
            @test_throws ArgumentError PriorityQueue(Reverse, ['a'])
            @test_throws ArgumentError PriorityQueue{Char,Int}(Base.Order.Reverse, ['a'])
        end

        @testset "Silly test" begin
            @test_throws ArgumentError PriorityQueue(Reverse, Reverse)
        end

    end

    @testset "PriorityQueueMethods" begin
        pq1 = PriorityQueue('a'=>1, 'b'=>2)

        @testset "peek/get/dequeue!" begin
            @test peek(pq1) == ('a'=>1)
            @test get(pq1, 'a', 0) == 1
            @test get(pq1, 'c', 0) == 0
            @test dequeue!(pq1) == 'a'
            @test dequeue!(pq1) == 'b'
        end

        pmax = 1000
        n = 10000
        ks, vs = 1:n, rand(1:pmax, n)
        priorities = Dict(zip(ks, vs))

        @testset "peek" begin
            pq1 = PriorityQueue(priorities)
            lowpri = findmin(vs)
            @test peek(pq1)[2] == pq1[ks[lowpri[2]]]
        end

        @testset "enqueue error throw" begin
            ks, vs = 1:n, rand(1:pmax, n)
            pq = PriorityQueue(zip(ks, vs))
            @test_throws ArgumentError enqueue!(pq, 1, 10)
        end

        @testset "Iteration" begin
            pq = PriorityQueue(priorities)
            pq2 = PriorityQueue()
            for kv in pq
                enqueue!(pq2, kv)
            end
            @test pq == pq2
        end

        @testset "enqueing pairs via enqueue!" begin
            pq = PriorityQueue()
            for kv in priorities
                enqueue!(pq, kv)
            end
            test_issorted!(pq, priorities)
        end

        @testset "enqueing values via enqueue!" begin
            pq = PriorityQueue()
            for (k, v) in priorities
                enqueue!(pq, k, v)
            end
            test_issorted!(pq, priorities)
        end

        @testset "enqueing via assign" begin
            pq = PriorityQueue()
            for (k, v) in priorities
                pq[k] = v
            end
            test_issorted!(pq, priorities)
        end

        @testset "changing priorities" begin
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
        end

        @testset "dequeuing" begin
            pq = PriorityQueue(priorities)
            @test_throws KeyError dequeue!(pq, 0)

            @test 10 == dequeue!(pq, 10)
            while !isempty(pq)
                @test 10 != dequeue!(pq)
            end
        end

        @testset "dequeuing pair" begin
            priorities2 = Dict(zip('a':'e', 5:-1:1))
            pq = PriorityQueue(priorities2)
            @test_throws KeyError dequeue_pair!(pq, 'g')
            @test dequeue_pair!(pq) == ('e'=> 1)
            @test dequeue_pair!(pq, 'b') == ('b'=>4)
            @test length(pq) == 3
        end
    end

    @testset "LowLevelHeapOperations" begin
        pmax = 1000
        n = 10000
        r = rand(1:pmax, n)
        priorities = Dict(zip(1:n, r))

        @testset "low level heap operations" begin
            xs = heapify!([v for v in values(priorities)])
            @test issorted([heappop!(xs) for _ in length(priorities)])
        end

        @testset "heapify/issorted" begin
            xs = heapify(10:-1:1)
            @test issorted([heappop!(xs) for _ in 1:10])
        end

        @testset "heappush!" begin
            xs = Vector{Int}()
            for priority in values(priorities)
                heappush!(xs, priority)
            end
            @test issorted([heappop!(xs) for _ in length(priorities)])
        end

        @testset "isheap" begin
            @test isheap([1, 2, 3], Base.Order.Forward)
            @test !isheap([1, 2, 3], Base.Order.Reverse)
        end
    end

end # @testset "PriorityQueue"
