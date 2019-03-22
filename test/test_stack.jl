@testset "Stacks" begin

    @testset "Constructors" begin
        s = Stack{Int}()
        @test isa(s, Stack{Int})

        s = Stack{Int}(5)
        @test isa(s, Stack{Int})

        # deprecated
        # s = Stack(Int)
        # s = Stack(Int, 5)
    end

    @testset "Core Functionality" begin
        s = Stack{Int}(5)
        n = 100

        @test isa(s, Stack{Int})
        @test length(s) == 0
        @test isempty(s)
        @test_throws ArgumentError top(s)
        @test_throws ArgumentError pop!(s)

        for i = 1 : n
            push!(s, i)
            @test top(s) == i
            @test !isempty(s)
            @test length(s) == i
        end

        for i = 1 : n
            x = pop!(s)
            @test x == n - i + 1
            if i < n
                @test top(s) == n - i
            else
                @test_throws ArgumentError top(s)
            end
            @test isempty(s) == (i == n)
            @test length(s) == n - i
        end
    end
    
    @testset "empty!" begin
        s = Stack{Int}(1)
        push!(s, 10)
        @test length(empty!(s)) == 0
    end

    @testset "iter should return a LIFO collection" begin
        stk = Stack{Int}(10)
        #an array to check iteration sequence against
        arr = Int64[]

        n = 100

        for i = 1:n
            push!(stk, i)
            push!(arr, i)
        end

        @testset "iterator" begin
            index = length(arr)
            for i in stk
                @test(arr[index] == i)
                index -= 1
            end
        end

        @testset "reverse iterator" begin
            index = 1
            for i in reverse_iter(stk)
                @test(arr[index] == i)
                index += 1
            end
        end

        @test arr == [i for i in reverse_iter(stk)]
        @test reverse(arr) == [i for i in stk]
    end

    @testset "show" begin
        s = Stack{Int}()
        intstr = sprint(show, Int)
        @test sprint(show, s) == "0-element Stack{$(intstr)}"
        push!(s, 1)
        @test sprint(show, s) == "1-element Stack{$(intstr)}:\n 1"
        for i in 2:50
            push!(s, i)
        end
        @test sprint(show, s) == "50-element Stack{$(intstr)}:\n 50\n 49\n 48\n 47\n 46\n 45\n 44\n 43\n 42\n 41\n 40\n 39\n 38\n 37\n 36\n 35\n 34\n 33\n 32\n 31\n 30\n 29\n 28\n 27\n 26\n 25\n 24\n 23\n 22\n 21\n 20\n 19\n 18\n 17\n 16\n 15\n 14\n 13\n 12\n 11\n 10\n  9\n  8\n  7\n  6\n  5\n  4\n  3\n  2\n  1"
        @test sprint((io,x) -> show(IOContext(io, :limit=>true), x), s) == "50-element Stack{$(intstr)}:\n 50\n 49\n 48\n 47\n 46\n 45\n 44\n 43\n 42\n 41\n  ⋮\n  9\n  8\n  7\n  6\n  5\n  4\n  3\n  2\n  1"
        pop!(s)
        @test sprint(show, s) == "49-element Stack{$(intstr)}:\n 49\n 48\n 47\n 46\n 45\n 44\n 43\n 42\n 41\n 40\n 39\n 38\n 37\n 36\n 35\n 34\n 33\n 32\n 31\n 30\n 29\n 28\n 27\n 26\n 25\n 24\n 23\n 22\n 21\n 20\n 19\n 18\n 17\n 16\n 15\n 14\n 13\n 12\n 11\n 10\n  9\n  8\n  7\n  6\n  5\n  4\n  3\n  2\n  1"
        @test sprint((io,x) -> show(IOContext(io, :limit=>true), x), s) == "49-element Stack{$(intstr)}:\n 49\n 48\n 47\n 46\n 45\n 44\n 43\n 42\n 41\n 40\n  ⋮\n  9\n  8\n  7\n  6\n  5\n  4\n  3\n  2\n  1"
    end

end # @testset Stack
