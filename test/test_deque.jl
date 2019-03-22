@testset "Deque" begin
    @testset "empty dequeue" begin
        @testset "empty dequeue 1" begin
            q = Deque{Int}()
            @test length(q) == 0
            @test isempty(q)
            @test q.blksize == DataStructures.DEFAULT_DEQUEUE_BLOCKSIZE
            @test_throws ArgumentError front(q)
            @test_throws ArgumentError back(q)
            @test length(sprint(dump,q)) >= 0
        end

        @testset "empty dequeue 2" begin
            @test typeof(deque(Int)) === typeof(Deque{Int}())
        end

        @testset "empty dequeue 3" begin
            q = DataStructures.DequeBlock{Int}(0,0)
            @test length(q) == 0
            @test capacity(q) == 0
            @test isempty(q)
            @test length(sprint(show,q)) >= 0
        end

        @testset "empty dequeue 4" begin
            q = Deque{Int}(3)
            @test length(q) == 0
            @test isempty(q)
            @test q.blksize == 3
            @test num_blocks(q) == 1
            @test_throws ArgumentError front(q)
            @test_throws ArgumentError back(q)
            @test isa(collect(q), Vector{Int})
            @test collect(q) == Int[]
        end
    end

    @testset "Core Functionality" begin
        n = 10
        
        @testset "push back / pop back" begin
            q = Deque{Int}(3)
            
            @testset "push back" begin
                for i = 1 : n
                    push!(q, i)
                    @test length(q) == i
                    @test isempty(q) == false
                    @test num_blocks(q) == div(i-1, 3) + 1

                    @test front(q) == 1
                    @test back(q) == i

                    k = 1
                    for j in q
                        @test j == k
                        k += 1
                    end
                    cq = collect(q)
                    @test isa(cq, Vector{Int})
                    @test cq == collect(1:i)
                    @test length(sprint(show,q)) >= 0
                end
            end

            @testset "pop back" begin
                for i = 1 : n
                    x = pop!(q)
                    @test length(q) == n - i
                    @test isempty(q) == (i == n)
                    @test num_blocks(q) == div(n-i-1, 3) + 1
                    @test x == n - i + 1

                    if !isempty(q)
                        @test front(q) == 1
                        @test back(q) == n - i
                    else
                        @test_throws ArgumentError front(q)
                        @test_throws ArgumentError back(q)
                    end

                    cq = collect(q)
                    @test cq == collect(1:n-i)
                end
            end
        end

        @testset "push front / pop front" begin
            q = Deque{Int}(3)

            @testset "push front" begin
                for i = 1 : n
                    pushfirst!(q, i)
                    @test length(q) == i
                    @test isempty(q) == false
                    @test num_blocks(q) == div(i-1, 3) + 1

                    @test front(q) == i
                    @test back(q) == 1

                    cq = collect(q)
                    @test isa(cq, Vector{Int})
                    @test cq == collect(i:-1:1)
                end
            end

            @testset "pop front" begin
                for i = 1 : n
                    x = popfirst!(q)
                    @test length(q) == n - i
                    @test isempty(q) == (i == n)
                    @test num_blocks(q) == div(n-i-1, 3) + 1
                    @test x == n - i + 1

                    if !isempty(q)
                        @test front(q) == n - i
                        @test back(q) == 1
                    else
                        @test_throws ArgumentError front(q)
                        @test_throws ArgumentError back(q)
                    end

                    cq = collect(q)
                    @test cq == collect(n-i:-1:1)
                end
            end
        end
    end

    @testset "random operations" begin
        q = Deque{Int}(5)
        r = Int[]
        m = 100

        for k = 1 : m
            la = rand(1:20)
            x = rand(1:1000, la)

            for i = 1 : la
                if rand(Bool)
                    push!(r, x[i])
                    push!(q, x[i])
                else
                    pushfirst!(r, x[i])
                    pushfirst!(q, x[i])
                end
            end

            @test length(q) == length(r)
            @test collect(q) == r

            lr = rand(1:length(r))
            for i = 1 : lr
                if rand(Bool)
                    pop!(r)
                    pop!(q)
                else
                    popfirst!(r)
                    popfirst!(q)
                end
            end

            @test length(q) == length(r)
            @test collect(q) == r
        end
    end

    @testset "hash and ==" begin
        a = Deque{Int64}(2)
        b = Deque{Int64}(3)
        # Note: blksize does not distinguish == or hash
        @test a == b
        @test hash(a) === hash(b)
        push!(a, 1)
        @test a != b
        push!(a, 2)
        push!(b, 2, 1)
        @test a != b
        @test hash(a) !== hash(b)
        popfirst!(b)
        push!(b, 2)
        @test a == b
        @test hash(a) == hash(b)
    end

    @testset "issue #38" begin
        q = Deque{Int}(1)
        push!(q,1)
        @test !isempty(q)
        empty!(q)
        @test isempty(q)
    end

    @testset "empty!" begin
        q = Deque{Int}(1)
        push!(q,1)
        push!(q,2)
        @test length(sprint(dump,q)) >= 0
        @test typeof(empty!(q)) === typeof(Deque{Int}())
        @test isempty(q)
    end

    @testset "show" begin
        q = Deque{Int}()
        intstr = sprint(show, Int)
        @test sprint(show, q) == "0-element Deque{$(intstr)}"
        @test sprint(show, q.head) == "0-element DataStructures.DequeBlock{$(intstr)}(capa = 1024, front = 1, back = 0)"
        push!(q, 1)
        @test sprint(show, q) == "1-element Deque{$(intstr)}:\n 1"
        @test sprint(show, q.head) == "1-element DataStructures.DequeBlock{$(intstr)}(capa = 1024, front = 1, back = 1):\n 1"
        for i in 2:50
            push!(q, i)
        end
        @test sprint(show, q) == "50-element Deque{$(intstr)}:\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n 11\n 12\n 13\n 14\n 15\n 16\n 17\n 18\n 19\n 20\n 21\n 22\n 23\n 24\n 25\n 26\n 27\n 28\n 29\n 30\n 31\n 32\n 33\n 34\n 35\n 36\n 37\n 38\n 39\n 40\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
        @test sprint((io, x) -> show(IOContext(io, :limit=>true), x), q) == "50-element Deque{$(intstr)}:\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n  ⋮\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
        @test sprint(show, q.head) == "50-element DataStructures.DequeBlock{$(intstr)}(capa = 1024, front = 1, back = 50):\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n 11\n 12\n 13\n 14\n 15\n 16\n 17\n 18\n 19\n 20\n 21\n 22\n 23\n 24\n 25\n 26\n 27\n 28\n 29\n 30\n 31\n 32\n 33\n 34\n 35\n 36\n 37\n 38\n 39\n 40\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
        @test sprint((io, x) -> show(IOContext(io, :limit=>true), x), q.head) == "50-element DataStructures.DequeBlock{$(intstr)}(capa = 1024, front = 1, back = 50):\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n  ⋮\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
        pop!(q)
        @test sprint(show, q) == "49-element Deque{$(intstr)}:\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n 11\n 12\n 13\n 14\n 15\n 16\n 17\n 18\n 19\n 20\n 21\n 22\n 23\n 24\n 25\n 26\n 27\n 28\n 29\n 30\n 31\n 32\n 33\n 34\n 35\n 36\n 37\n 38\n 39\n 40\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49"
        @test sprint((io, x) -> show(IOContext(io, :limit=>true), x), q) == "49-element Deque{$(intstr)}:\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n  ⋮\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49"
        @test sprint(show, q.head) == "49-element DataStructures.DequeBlock{$(intstr)}(capa = 1024, front = 1, back = 49):\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n 11\n 12\n 13\n 14\n 15\n 16\n 17\n 18\n 19\n 20\n 21\n 22\n 23\n 24\n 25\n 26\n 27\n 28\n 29\n 30\n 31\n 32\n 33\n 34\n 35\n 36\n 37\n 38\n 39\n 40\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49"
        @test sprint((io, x) -> show(IOContext(io, :limit=>true), x), q.head) == "49-element DataStructures.DequeBlock{$(intstr)}(capa = 1024, front = 1, back = 49):\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n  ⋮\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49"
    end

end # @testset Deque
