@testset "Queue" begin

    @testset "Constructors" begin
        s = Queue{Int}()
        @test isa(s, Queue{Int})

        s = Queue{Int}(5)
        @test isa(s, Queue{Int})
    end

    @testset "Core Functionality" begin
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

    @testset "==" begin
        t = Queue{Int}()
        s = Queue{Int}()

        @test s == t
        enqueue!(s, 10)
        @test s != t
        enqueue!(t, 10)
        @test s == t
        enqueue!(t, 20)
        @test s != t

        @testset "different types" begin
            r = Queue{Float32}()
            enqueue!(r, 10)
            @test s == r
        end
    end

    @testset "emptyness" begin
        s = Queue{Int}()
        enqueue!(s, 1)
        enqueue!(s, 3)
        @test !isempty(s)
        empty!(s)
        @test isempty(s)
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
            for i in Iterators.reverse(q)
                @test(arr[index] == i)
                index -= 1
            end
        end

        @test arr == [i for i in q]
        @test reverse(arr) == [i for i in Iterators.reverse(q)]
        @test first(Iterators.reverse(q)) === last(q)
        @test last(Iterators.reverse(q)) === first(q)
        @test length(Iterators.reverse(q)) === length(q)
    end

end # @testset Queue
