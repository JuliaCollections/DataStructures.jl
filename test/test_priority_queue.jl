# This was formerly a part of Julia. License is MIT: http://julialang.org/license

import Base.Order.Reverse


@testset "PriorityQueue" begin

    # Test dequeing in sorted order.
    function test_issorted!(pq::PriorityQueue, priorities, rev=false)
        last, _ = popfirst!(pq)
        while !isempty(pq)
            value, _ = popfirst!(pq)
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
            krcvd, _ = popat!(pq, krqst)
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
                @test first(pq9) == ('a'=>1)
            end

            @testset "pq10" begin
                pq10 = PriorityQueue(Reverse, 'a'=>1, 'b'=>2)
                @test first(pq10) == ('b'=>2)
            end

            @testset "pq11" begin
                pq11 = PriorityQueue(Pair{Char}['a'=>1,'b'=>2])
                @test first(pq11) == ('a'=>1)
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

        @testset "Strange eltype situations" begin
            @testset "Eltype unknown" begin
                struct EltypeUnknownIterator{T}
                    x::T
                end
                Base.IteratorEltype(::EltypeUnknownIterator) = Base.EltypeUnknown()
                Base.iterate(i::EltypeUnknownIterator) = Base.iterate(i.x)
                Base.iterate(i::EltypeUnknownIterator, state) = Base.iterate(i.x, state)
                Base.IteratorSize(i::EltypeUnknownIterator) = Base.IteratorSize(i.x)
                Base.length(i::EltypeUnknownIterator) = Base.length(i.x)
                Base.size(i::EltypeUnknownIterator) = Base.size(i.x)

                @test_nowarn PriorityQueue(Dict(zip(1:5, 2:6)))
                @test_nowarn PriorityQueue(EltypeUnknownIterator(Dict(zip(1:5, 2:6))))
                @test_throws ArgumentError PriorityQueue(EltypeUnknownIterator(['a']))
            end

            @testset "Eltype any" begin
                struct EltypeAnyIterator{T}
                    x::T
                end
                Base.IteratorEltype(::EltypeAnyIterator) = Base.HasEltype()
                Base.eltype(::EltypeAnyIterator) = Any
                Base.iterate(i::EltypeAnyIterator) = Base.iterate(i.x)
                Base.iterate(i::EltypeAnyIterator, state) = Base.iterate(i.x, state)
                Base.IteratorSize(i::EltypeAnyIterator) = Base.IteratorSize(i.x)
                Base.length(i::EltypeAnyIterator) = Base.length(i.x)
                Base.size(i::EltypeAnyIterator) = Base.size(i.x)

                @test_nowarn PriorityQueue(EltypeAnyIterator(Dict(zip(1:5, 2:6))))
                @test_throws ArgumentError PriorityQueue(EltypeAnyIterator(['a']))
            end
        end

    end

    @testset "PriorityQueueMethods" begin
        pq1 = PriorityQueue('a'=>1, 'b'=>2)

        @testset "first/get/popfirst!/get!" begin
            @test first(pq1) == ('a'=>1)
            @test get(pq1, 'a', 0) == 1
            @test get(pq1, 'c', 0) == 0
            @test get!(pq1, 'b', 20) == 2
            @test popfirst!(pq1).first == 'a'
            @test popfirst!(pq1).first == 'b'
            @test get!(pq1, 'c', 0) == 0
            @test first(pq1) == ('c'=>0)
            @test get!(pq1, 'c', 3) == 0
        end

        pmax = 1000
        n = 10000
        ks, vs = 1:n, rand(1:pmax, n)
        priorities = Dict(zip(ks, vs))

        @testset "first" begin
            pq1 = PriorityQueue(priorities)
            lowpri = findmin(vs)
            @test first(pq1)[2] == pq1[ks[lowpri[2]]]
        end

        @testset "enqueue error throw" begin
            ks, vs = 1:n, rand(1:pmax, n)
            pq = PriorityQueue(zip(ks, vs))
            @test_throws ArgumentError push!(pq, 1=>10)
        end

        @testset "Iteration" begin
            pq = PriorityQueue(priorities)
            pq2 = PriorityQueue()
            for kv in pq
                push!(pq2, kv)
            end
            @test pq == pq2
        end

        @testset "enqueing pairs via push!" begin
            pq = PriorityQueue()
            for kv in priorities
                push!(pq, kv)
            end
            test_issorted!(pq, priorities)
        end

        @testset "enqueing values via push!" begin
            pq = PriorityQueue()
            for (k, v) in priorities
                push!(pq, k=>v)
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
            @test_throws KeyError popat!(pq, 0)

            v, _ = popat!(pq, 10)
            @test v == 10
            while !isempty(pq)
                v, _ = popfirst!(pq)
                @test v != 10
            end

            pq = PriorityQueue(1.0 => 1)
            @test popat!(pq, 1.0f0) isa eltype(pq)
            @test eltype(pq) == Pair{Float64, Int64}

            priorities2 = Dict(zip('a':'e', 5:-1:1))
            pq = PriorityQueue(priorities2)
            @test_throws KeyError popat!(pq, 'g')
            @test popfirst!(pq) == ('e'=> 1)
            @test popat!(pq, 'b') == ('b'=>4)
            @test length(pq) == 3
        end

        @testset "delete!" begin
            pq = PriorityQueue(Base.Order.Forward, "a"=>2, "b"=>3, "c"=>1)
            pq_out = delete!(pq, "b")
            @test pq === pq_out
            @test Set(collect(pq)) == Set(["a"=>2, "c"=>1])
        end

        @testset "empty!" begin
            pq = PriorityQueue(Base.Order.Forward, "a"=>2, "b"=>3, "c"=>1)
            @test !isempty(pq)
            empty!(pq)
            @test isempty(pq)
            push!(pq, "a"=>2)
            @test length(pq) == 1
        end
    end

    @testset "Iteration" begin
        pq = PriorityQueue(["a" => 10, "b" => 5, "c" => 15])
        @test collect(pq)         == ["b" => 5, "a" => 10, "c" => 15]
        @test collect(keys(pq))   == ["b", "a", "c"]
        @test collect(values(pq)) == [5, 10, 15]
    end

    @testset "UnorderedIteration" begin
        pq = PriorityQueue(["a" => 10, "b" => 5, "c" => 15])
        res = Pair{String, Int}[]
        next = iterate(pq, false)
        while next !== nothing
            p, i = next
            push!(res, p)
            next = iterate(pq, i)
        end
        @test Set(res) == Set(["a" => 10, "b" => 5, "c" => 15])
        empty!(res)
        next = iterate(pq, true)
        while next !== nothing
            p, i = next
            push!(res, p)
            next = iterate(pq, i)
        end
        @test res == ["b" => 5, "a" => 10, "c" => 15]
    end

    # Copy and merge operations in PriorityQueue utilize unordered
    # iteration
    @testset "Copy and Merge" begin
        v = [i for i=10000:-1:1]
        pq1 = PriorityQueue(zip(v, 10 .* v))
        @test collect(merge!(Dict(), pq1)) != collect(pq1)
        pq = PriorityQueue(["a" => 10, "b" => 5, "c" => 15])
        sd = SortedDict(["d"=>6, "e"=>4])
        merge!(sd, pq)
        @test collect(sd) == ["a" => 10, "b" => 5, "c" => 15, "d" => 6, "e" => 4]
        d = merge!(Dict("d"=> 6), pq)
        @test Set(collect(d)) == Set(["c" => 15, "b" => 5, "a" => 10, "d" => 6])
        sd = SortedDict(["c"=>6, "e"=>4])
        merge!(+, sd, pq)
        @test collect(sd) == ["a" => 10, "b" => 5, "c" => 21, "e" => 4]
        pq1 = empty(pq)
        @test length(pq1) == 0
        pq1 = copy(pq)
        @test pq1 isa PriorityQueue
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

        @testset "percolate_down!" begin
            @testset "Basic percolate down" begin
                xs = [10, 2, 3, 4, 5]
                DataStructures.percolate_down!(xs, 1, 10, Base.Order.Forward)
                @test xs == [2, 4, 3, 10, 5]
            end

            @testset "Element in correct position" begin
                xs = [1, 2, 3, 4, 5]
                DataStructures.percolate_down!(xs, 1, 1, Base.Order.Forward)
                @test xs == [1, 2, 3, 4, 5]
            end

            @testset "Reverse ordering" begin
                xs = [1, 5, 4, 3, 2]
                DataStructures.percolate_down!(xs, 1, 1, Base.Order.Reverse)
                @test xs == [5, 3, 4, 1, 2]
            end

            @testset "Custom length" begin
                xs = [10, 2, 3, 4, 5]
                DataStructures.percolate_down!(xs, 1, 10, Base.Order.Forward, 3)
                @test xs == [2, 10, 3, 4, 5]
            end

            @testset "Without explicit x parameter" begin
                xs = [10, 2, 3, 4, 5]
                DataStructures.percolate_down!(xs, 1, Base.Order.Forward)
                @test xs == [2, 4, 3, 10, 5]

                xs = [10, 2, 3, 4, 5]
                DataStructures.percolate_down!(xs, 1)
                @test xs == [2, 4, 3, 10, 5]
            end

            @testset "From middle position" begin
                xs = [2, 0, 3, 4, 5]
                DataStructures.percolate_down!(xs, 2, 10, Base.Order.Forward)
                @test xs == [2, 4, 3, 10, 5]
            end
        end

        @testset "percolate_up!" begin
            @testset "Basic percolate up" begin
                xs = [1, 2, 3, 4, 0]
                DataStructures.percolate_up!(xs, 5, 0, Base.Order.Forward)
                @test xs == [0, 1, 3, 4, 2]
            end

            @testset "Element in correct position" begin
                xs = [1, 2, 3, 4, 5]
                DataStructures.percolate_up!(xs, 5, 5, Base.Order.Forward)
                @test xs == [1, 2, 3, 4, 5]
            end

            @testset "Reverse ordering" begin
                xs = [5, 4, 3, 2, 10]
                DataStructures.percolate_up!(xs, 5, 10, Base.Order.Reverse)
                @test xs == [10, 5, 3, 2, 4]
            end

            @testset "Percolate to root" begin
                xs = [2, 3, 4, 5, 1]
                DataStructures.percolate_up!(xs, 5, 1, Base.Order.Forward)
                @test xs == [1, 2, 4, 5, 3]
            end

            @testset "Without explicit x parameter" begin
                xs = [1, 2, 3, 4, 0]
                DataStructures.percolate_up!(xs, 5, Base.Order.Forward)
                @test xs == [0, 1, 3, 4, 2]

                xs = [1, 2, 3, 4, 0]
                DataStructures.percolate_up!(xs, 5)
                @test xs == [0, 1, 3, 4, 2]
            end

            @testset "From middle position" begin
                xs = [1, 5, 3, 10, 8]
                DataStructures.percolate_up!(xs, 4, 0, Base.Order.Forward)
                @test xs == [0, 1, 3, 5, 8]
            end
        end
    end
end # @testset "PriorityQueue"
