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

end # @testset Queue