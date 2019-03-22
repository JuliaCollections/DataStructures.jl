@testset "Queue" begin

    @testset "Constructors" begin
        s = Queue{Int}()
        @test isa(s, Queue{Int})

        s = Queue{Int}(5)
        @test isa(s, Queue{Int})
        
        # deprecated
        # s = Queue(Int)
        # s = Queue(Int, 5)
    end

    @testset "Core Functionality" begin
        s = Queue{Int}(5)
        n = 100

        @test length(s) == 0
        @test isempty(s)
        @test_throws ArgumentError front(s)
        @test_throws ArgumentError back(s)
        @test_throws ArgumentError dequeue!(s)

        for i = 1 : n
            enqueue!(s, i)
            @test front(s) == 1
            @test back(s) == i
            @test !isempty(s)
            @test length(s) == i
        end

        for i = 1 : n
            x = dequeue!(s)
            @test x == i
            if i < n
                @test front(s) == i + 1
                @test back(s) == n
            else
                @test_throws ArgumentError front(s)
                @test_throws ArgumentError back(s)
            end
            @test isempty(s) == (i == n)
            @test length(s) == n - i
        end
    end

    @testset "iter should return a FIFO collection" begin
        q = Queue{Int}(10)
        n = 100

        #an array to check iteration sequence against
        arr = Int64[]

        for i = 1:n
            enqueue!(q,i)
            push!(arr,i)
        end

        @testset "iterator" begin
            index = 1
            for i in q
                @test(arr[index] == i)
                index += 1
            end
        end

        @testset "reverse iterator" begin
            index = length(arr)
            for i in reverse_iter(q)
                @test(arr[index] == i)
                index -= 1
            end
        end

        @test arr == [i for i in q]
        @test reverse(arr) == [i for i in reverse_iter(q)]
    end

    @testset "show" begin
        q = Queue{Int}()
        intstr = sprint(show, Int)
        @test sprint(show, q) == "0-element Queue{$(intstr)}"
        enqueue!(q, 1)
        @test sprint(show, q) == "1-element Queue{$(intstr)}:\n 1"
        for i in 2:50
            enqueue!(q, i)
        end
        @test sprint((io, x) -> show(IOContext(io, :limit=>true), x), q) == "50-element Queue{$(intstr)}:\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n  ⋮\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
        @test sprint(show, q) == "50-element Queue{$(intstr)}:\n  1\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n 11\n 12\n 13\n 14\n 15\n 16\n 17\n 18\n 19\n 20\n 21\n 22\n 23\n 24\n 25\n 26\n 27\n 28\n 29\n 30\n 31\n 32\n 33\n 34\n 35\n 36\n 37\n 38\n 39\n 40\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
        dequeue!(q)
        @test sprint((io, x) -> show(IOContext(io, :limit=>true), x), q) == "49-element Queue{$(intstr)}:\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n 11\n  ⋮\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
        @test sprint(show, q) == "49-element Queue{$(intstr)}:\n  2\n  3\n  4\n  5\n  6\n  7\n  8\n  9\n 10\n 11\n 12\n 13\n 14\n 15\n 16\n 17\n 18\n 19\n 20\n 21\n 22\n 23\n 24\n 25\n 26\n 27\n 28\n 29\n 30\n 31\n 32\n 33\n 34\n 35\n 36\n 37\n 38\n 39\n 40\n 41\n 42\n 43\n 44\n 45\n 46\n 47\n 48\n 49\n 50"
    end

end # @testset Queue