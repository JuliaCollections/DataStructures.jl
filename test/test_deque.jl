@testset "Deque" begin
    @testset "empty dequeue" begin
        @testset "empty dequeue 1" begin
            q = Deque{Int}()
            @test length(q) == 0
            @test isempty(q)
            @test eltype(q) == Int
            @test eltype(typeof(q)) == Int
            @test q.blksize == DataStructures.DEFAULT_DEQUEUE_BLOCKSIZE
            @test_throws ArgumentError first(q)
            @test_throws ArgumentError last(q)
            @test length(sprint(dump,q)) >= 0
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
            @test_throws ArgumentError first(q)
            @test_throws ArgumentError last(q)
            @test isa(collect(q), Vector{Int})
            @test collect(q) == Int[]
        end
    end

    @testset "Core Functionality" begin
        n = 10

        @testset "push last / pop last" begin
            q = Deque{Int}(3)

            @testset "push last" begin
                for i = 1 : n
                    push!(q, i)
                    @test length(q) == i
                    @test isempty(q) == false
                    @test num_blocks(q) == div(i-1, 3) + 1

                    @test first(q) == 1
                    @test last(q) == i

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

            @testset "pop last" begin
                for i = 1 : n
                    x = pop!(q)
                    @test length(q) == n - i
                    @test isempty(q) == (i == n)
                    @test num_blocks(q) == div(n-i-1, 3) + 1
                    @test x == n - i + 1

                    if !isempty(q)
                        @test first(q) == 1
                        @test last(q) == n - i
                    else
                        @test_throws ArgumentError first(q)
                        @test_throws ArgumentError last(q)
                    end

                    cq = collect(q)
                    @test cq == collect(1:n-i)
                end
            end
        end

        @testset "push first / pop first" begin
            q = Deque{Int}(3)

            @testset "push first" begin
                for i = 1 : n
                    pushfirst!(q, i)
                    @test length(q) == i
                    @test isempty(q) == false
                    @test num_blocks(q) == div(i-1, 3) + 1

                    @test first(q) == i
                    @test last(q) == 1

                    cq = collect(q)
                    @test isa(cq, Vector{Int})
                    @test cq == collect(i:-1:1)
                end
            end

            @testset "pop first" begin
                for i = 1 : n
                    x = popfirst!(q)
                    @test length(q) == n - i
                    @test isempty(q) == (i == n)
                    @test num_blocks(q) == div(n-i-1, 3) + 1
                    @test x == n - i + 1

                    if !isempty(q)
                        @test first(q) == n - i
                        @test last(q) == 1
                    else
                        @test_throws ArgumentError first(q)
                        @test_throws ArgumentError last(q)
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

    VERSION >= v"1.3" && @testset "pop! and popfirst! don't leak" begin
        q = Deque{String}(5)
        GC.gc(true)

        @testset "pop! doesn't leak" begin
            push!(q,"foo")
            push!(q,"bar")
            ss2 = Base.summarysize(q.head)
            pop!(q)
            GC.gc(true)
            ss1 = Base.summarysize(q.head)
            @test ss1 < ss2
        end
        @testset "popfirst! doesn't leak" begin
            push!(q,"baz")
            push!(q,"bug")
            ss2 = Base.summarysize(q.head)
            popfirst!(q)
            GC.gc(true)
            ss1 = Base.summarysize(q.head)
            @test ss1 < ss2
        end
    end
end # @testset Deque
