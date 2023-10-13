m(x...) = MutableLinkedList{Int}(x...)

@testset "MutableLinkedList" begin

    @testset "empty list" begin
        l1 = MutableLinkedList{Int}()
        @test MutableLinkedList() == MutableLinkedList{Any}()
        @test iterate(l1) === nothing
        @test isempty(l1)
        @test length(l1) == 0
        @test lastindex(l1) == 0
        @test collect(l1) == Int[]
        @test eltype(l1) == Int
        @test eltype(typeof(l1)) == Int
        @test_throws ArgumentError pop!(l1)
        @test_throws ArgumentError popfirst!(l1)
    end

    @testset "core functionality" begin
        n = 10

        @testset "push back / pop back" begin
            l = MutableLinkedList{Int}()

            @testset "push back" begin
                for i = 1:n
                    push!(l, i)
                    @test last(l) == i
                    if i > 4
                        @test getindex(l, i) == i
                        @test getindex(l, 1:floor(Int, i / 2)) == MutableLinkedList{Int}(1:floor(Int, i / 2)...)
                        @test l[1:floor(Int, i / 2)] == MutableLinkedList{Int}(1:floor(Int, i / 2)...)
                        setindex!(l, 0, i - 2)
                        @test l == MutableLinkedList{Int}(1:i-3..., 0, i-1:i...)
                        setindex!(l, i - 2, i - 2)
                    end
                    @test lastindex(l) == i
                    @test length(l) == i
                    @test isempty(l) == false
                    for (j, k) in enumerate(l)
                        @test j == k
                    end
                    if i > 3
                        l1 = MutableLinkedList{Int32}(1:i...)
                        io = IOBuffer()
                        @test sprint(io -> show(io, iterate(l1))) == "(1, DataStructures.ListNode{Int32}(2))"
                        @test sprint(io -> show(io, iterate(l1, l1.node.next.next))) == "(2, DataStructures.ListNode{Int32}(3))"
                    end
                    cl = collect(l)
                    @test isa(cl, Vector{Int})
                    @test cl == collect(1:i)
                end
            end

            @testset "pop back" begin
                for i = 1:n
                    x = pop!(l)
                    @test length(l) == n - i
                    @test isempty(l) == (i == n)
                    @test x == n - i + 1
                    cl = collect(l)
                    @test cl == collect(1:n-i)
                end
            end
        end

        @testset "push front / pop front" begin
            l = MutableLinkedList{Int}()

            @testset "push front" begin
                for i = 1:n
                    pushfirst!(l, i)
                    @test first(l) == i
                    @test length(l) == i
                    @test isempty(l) == false
                    cl = collect(l)
                    @test isa(cl, Vector{Int})
                    @test cl == collect(i:-1:1)
                end
            end

            @testset "pop front" begin
                for i = 1:n
                    x = popfirst!(l)
                    @test length(l) == n - i
                    @test isempty(l) == (i == n)
                    @test x == n - i + 1
                    cl = collect(l)
                    @test cl == collect(n-i:-1:1)
                end
            end

        end

        @testset "append / delete / copy / reverse" begin
            for i = 1:n
                l = MutableLinkedList{Int}(1:n...)

                @testset "append" begin
                    l2 = MutableLinkedList{Int}(n+1:2n...)
                    append!(l, l2)
                    @test l == MutableLinkedList{Int}(1:2n...)
                    @test collect(l) == collect(MutableLinkedList{Int}(1:2n...))
                    l3 = MutableLinkedList{Int}(1:n...)
                    append!(l3, n+1:2n...)
                    @test l3 == MutableLinkedList{Int}(1:2n...)
                    @test collect(l3) == collect(MutableLinkedList{Int}(1:2n...))
                end

                @testset "delete" begin
                    delete!(l, n+1:2n)
                    @test l == MutableLinkedList{Int}(1:n...)
                    for i = n:-1:1
                        delete!(l, i)
                    end
                    @test l == MutableLinkedList{Int}()
                    l = MutableLinkedList{Int}(1:n...)
                    @test_throws BoundsError delete!(l, n-1:2n)
                    @test_throws BoundsError delete!(l, 2n)
                end

                @testset "copy" begin
                    l2 = copy(l)
                    @test l == l2
                end

                @testset "reverse" begin
                    l2 = MutableLinkedList{Int}(n:-1:1...)
                    @test l == reverse(l2)
                end
            end
        end

        @testset "map / filter" begin
            for i = 1:n
                @testset "map" begin
                    l = MutableLinkedList{Int}(1:n...)
                    @test map(x -> 2x, l) == MutableLinkedList{Int}(2:2:2n...)
                    l2 = MutableLinkedList{Float64}()
                    @test map(x -> x * im, l2) == MutableLinkedList{Complex{Float64}}()
                    @test map(Int32, l2) == MutableLinkedList{Int32}()
                    f(x) = x % 2 == 0 ? convert(Int8, x) : convert(Float16, x)
                    @test typeof(map(f, l)) == MutableLinkedList{Real}
                end

                @testset "filter" begin
                    l = MutableLinkedList{Int}(1:n...)
                    @test filter(x -> x % 2 == 0, l) == MutableLinkedList{Int}(2:2:n...)
                end

            end
        end
    end

    @testset "random operations" begin
        l = MutableLinkedList{Int}()
        r = Int[]
        m = 100

        for k = 1:m
            la = rand(1:20)
            x = rand(1:1000, la)

            for i = 1:la
                if rand(Bool)
                    push!(r, x[i])
                    push!(l, x[i])
                else
                    pushfirst!(r, x[i])
                    pushfirst!(l, x[i])
                end
            end

            @test length(l) == length(r)
            @test collect(l) == r

            lr = rand(1:length(r))
            for i = 1:lr
                if rand(Bool)
                    pop!(r)
                    pop!(l)
                else
                    popfirst!(r)
                    popfirst!(l)
                end
            end

            @test length(l) == length(r)
            @test collect(l) == r
        end
    end
end
@testset "MutableLinkedList: verbose function tests" begin

    @testset "empty!" begin
        l = MutableLinkedList(1, 2, 3)
        @test !isempty(l)
        @test empty!(l) == MutableLinkedList{Int}()
        @test isempty(l)
        @test l == MutableLinkedList{Int}()
        @test length(l) == 0
        @test l.node == l.node.next == l.node.prev
    end

    @testset "show" begin
        l = MutableLinkedList{Int32}(1:2...)
        io = IOBuffer()
        @test sprint(io -> show(io, l.node.next)) == "$(typeof(l.node.next))($(l.node.next.data))"
        @test sprint(show, MutableLinkedList{Int32}()) == """
         0-element MutableLinkedList{Int32}:
         """
        @test sprint(show, MutableLinkedList{Int32}(1:2...)) == """
         2-element MutableLinkedList{Int32}:
         1
         2"""
        @test sprint(show, MutableLinkedList{Int32}(1)) == """
         1-element MutableLinkedList{Int32}:
         1"""
        @test sprint(show, MutableLinkedList{UInt8}(1:2...)) == """
         2-element MutableLinkedList{UInt8}:
         0x01
         0x02"""
        l = MutableLinkedList{Int}(1:1000...)
        p = sprint(show, l; context=(:limit => true, :displaysize => (10, 10)))
        @test p == """1000-element MutableLinkedList{$(string(Int))}:
        1
        2
        3
        ⋮
        998
        999
        1000"""
        p = sprint(show, l; context=(:limit => true, :displaysize => (9, 10)))
        @test p == """1000-element MutableLinkedList{$(string(Int))}:
        1
        2
        3
        ⋮
        999
        1000"""
        iob = IOBuffer()
        print(iob, "1000-element MutableLinkedList{$(string(Int))}:\n")
        for i in 1:1000
            print(iob, i, i != 1000 ? "\n" : "")
        end
        p = sprint(show, l; context=(:limit => false, :displaysize => (9, 10)))
        @test p == String(take!(iob))
    end


    @testset "popat!" begin
        l = m(1,2,3)
        @test popat!(l,10,100) == 100
        @test popat!(l,2) == 2
        @test l == m(1,3)
        @test popat!(l,1) == 1
        @test l == m(3)
        @test popat!(l,1) == 3
        @test l == m()
        @test_throws BoundsError popat!(l,3)
        @test popat!(l,11,111) == 111
    end

    @testset "pop!" begin
        l = m(1,2,3)
        @test pop!(l) == 3
        @test l == m(1,2)
        @test pop!(l) == 2
        @test l == m(1)
        @test pop!(l) == 1
        @test l == m()
        @test_throws ArgumentError pop!(l)
    end

    @testset "popfirst!" begin
        l = m(1,2,3)
        @test popfirst!(l) == 1
        @test l == m(2,3)
        @test popfirst!(l) == 2
        @test l == m(3)
        @test popfirst!(l) == 3
        @test l == m()
        @test_throws ArgumentError popfirst!(l)
    end

    @testset "push!" begin
        @test push!(m(),1) == m(1)
        l = m(5,6,7)
        res = push!(l,8)
        @test res == m(5,6,7,8)
        @test l === res
        @test push!(l,9) == m(5,6,7,8,9)
    end

    @testset "pushfirst!" begin
        @test pushfirst!(m(),1) == m(1)
        l = m(5,6,7)
        res = pushfirst!(l,4)
        @test res == m(4,5,6,7)
        @test l === res
        @test pushfirst!(l,3) == m(3,4,5,6,7)
    end

    @testset "append!" begin
        l = m()
        @test append!(l, []) == m()
        @test append!(l, [1]) == m(1)
        @test append!(l, [2, 3]) == m(1, 2, 3)
        @test append!(l, [4, 5], [], [6, 7]) == m(1, 2, 3, 4, 5, 6, 7)
        @test l == m(1, 2, 3, 4, 5, 6, 7)
        l1 = m(4, 5, 6)
        l2 = m(7, 8, 9)
        @test append!(l1, l2) == m(4, 5, 6, 7, 8, 9)
        @test l2 == m(7, 8, 9) # append! should not mutate other arguments
    end

    @testset "prepend!" begin
        l = m()
        @test prepend!(l, []) == m()
        @test prepend!(l, [1]) == m(1)
        @test prepend!(l, [3, 2]) == m(3, 2, 1)
        @test prepend!(l, [7, 6], [], [5, 4]) == m(7, 6, 5, 4, 3, 2, 1)
        @test l == m(7, 6, 5, 4, 3, 2, 1)
        l1 = m(4, 5, 6)
        l2 = m(7, 8, 9)
        @test prepend!(l2, l1) == m(4, 5, 6, 7, 8, 9)
        @test l1 == m(4, 5, 6) # prepend! should not mutate other arguments
    end

    @testset "copy" begin
        l = m()
        @test lc = copy(l) == m()
        l = m(10, 20)
        lc = copy(l)
        @test lc == l
        @test lc == m(10, 20)
        @test lc !== l
        @test lc.node !== l.node
        @test lc.node.next !== l.node.next # 10
        @test lc.node.next.next !== l.node.next # 20
        @test lc.node.next.next.next !== l.node # back again
        @test lc.node.prev !== l.node.prev # 20
        @test lc.node.prev.prev !== l.node.prev # 10
        @test lc.node.prev.prev.prev !== l.node # back again
        @test length(l) == length(lc)
    end

    @testset "reverse" begin
        @test m() == reverse(m())
        l1 = m(1, 2, 3)
        l2 = reverse(m(3, 2, 1))
        @test l1 == l2
        l1 = m(1, 2, 3)
        l2 = reverse(l1)
        @test l1.node !== l2.node
        l1[3] = 33
        l2[2] = 22
        @test l1 == m(1, 2, 33)
        @test l2 == m(3, 22, 1) # check for aliasing
    end

    @testset "reverse!" begin
        @test m() == reverse!(m())
        l1 = m(1, 2, 3)
        l2 = reverse!(l1)
        @test l1 === l2
        @test l1 == m(3, 2, 1)
        @test reverse!(m(1)) == m(1)
        @test reverse!(m(1, 2)) == m(2, 1)
    end

    @testset "deleteat!" begin
        @test_throws BoundsError deleteat!(m(), 0)
        @test_throws BoundsError deleteat!(m(1, 2, 3), 100)
        l = m(1, 2, 3, 4)
        @test deleteat!(l, 1) == m(2, 3, 4)
        @test deleteat!(l, 3) == m(2, 3)
        @test deleteat!(l, 2) == m(2)
        @test deleteat!(l, 1) == m()
    end

    @testset "map" begin
        l = m(1, 2, 3)
        @test map(x -> 2x, l) == m(2, 4, 6)
        l = m(1, 2, 3)
        lm = map(x -> 2x % UInt8, l)
        @test lm == MutableLinkedList{UInt8}(0x02, 0x04, 0x06)
        @test eltype(lm) == UInt8
        @test map(abs, m(1, -2, 3)) == m(1, 2, 3)
        l = m()
        lm = map(abs, l)
        @test lm == l
        @test lm !== l
        @test map(string, m(1, 2, 3)) == MutableLinkedList{String}("1", "2", "3")
        l = m(1, 2, 3, 4)
        f(x) = x % 2 == 0 ? convert(Int8, x) : convert(Float16, x)
        @test typeof(map(f, l)) == MutableLinkedList{Real}
    end

    @testset "filter" begin
        l = m(1, 2, 3)
        @test filter(iseven, l) == m(2)
        @test filter(isodd, l) == m(1, 3)
        @test filter(isodd, m()) == m()
    end

    @testset "filter!" begin
        l = m(1, 2, 3, 4, 5)
        filter!(iseven, l)
        @test l == m(2, 4)
        @test l !== m(2, 4)
        filter!(isodd, l)
        @test l == m()
        l = m()
        @test filter!(isodd, l) == m()
        @test filter!(x -> x < 0, m(1, 2, 3)) == m()
        @test filter!(x -> x > 0, m(1, 2, 3)) == m(1, 2, 3)
    end

    @testset "splice! with no replacement" begin
        l = m(1, 2, 3)
        @test splice!(l, 2) == 2
        @test l == m(1, 3)
        @test splice!(l, 1) == 1
        @test l == m(3)
        @test splice!(l, 1) == 3
        @test l == m()

        l = m(1:10...)
        @test splice!(l, 8:10) == m(8, 9, 10)
        @test l == m(1:7...)
        @test splice!(l, 1:3) == m(1, 2, 3)
        @test l == m(4, 5, 6, 7)
        @test splice!(l, 1:0) == m()
        @test l == m(4, 5, 6, 7)
        @test splice!(l, 1:1) == 4
        @test l == m(5, 6, 7)

        @test_throws BoundsError splice!(m(), 1)
        @test_throws BoundsError splice!(m(), 1:1)
    end

    @testset "splice! with replacement" begin
        l = m(1, 2, 3)
        @test splice!(l, 1, 11) == 1
        @test l == m(11, 2, 3)
        @test splice!(l, 2, 22) == 2
        @test l == m(11, 22, 3)
        @test splice!(l, 3, 33) == 3
        @test l == m(11, 22, 33)
        @test splice!(l, 2:3, [222, 333]) == m(22, 33)
        @test l == m(11, 222, 333)
        @test splice!(l, 4:0, [444]) == m()
        @test l == m(11, 222, 333, 444)
        @test splice!(l, 1:4, []) == m(11, 222, 333, 444)
        @test l == m()
        @test splice!(l, 1:0, [7, 8, 9]) == m()
        @test l == m(7, 8, 9)
        @test splice!(l, 4:0, [10, 11]) == m()
        @test l == m(7, 8, 9, 10, 11)
        @test splice!(l, 5:5, [111, 112]) == 11
        @test l == m(7, 8, 9, 10, 111, 112)
    end
end
@testset "MutableLinkedList: comparison against `Vector`" begin

    function compare!(v, l, f, args...)
        vres = try
            f(v, args...)
        catch e
            e
        end
        lres = try
            f(l, args...)
        catch e
            e
        end
        VT, LT = typeof(vres), typeof(lres)
        if (VT <: Exception) ⊻ (LT <: Exception)
            @info "compare!" v, l, f, args
        end
        @test !((VT <: Exception) ⊻ (LT <: Exception))

        if VT <: Exception
            @test VT == LT
        else

            @test all(vres .== lres)
            @test all(v .== l)
        end
    end
    # comparison for non mutating functions
    function compare(l, f, args...)
        lc = copy(l)
        v = collect(l)
        lres = compare!(v, l, f, args...)
        @test lc == l
        @test lres !== l
    end

    for _ in 1:10
        n = rand(0:10)              # length of list (can include the empty list)
        v = rand(Int, n)            # vector for comparison
        l = m(v...)                 # list for comparison
        i, j = rand(0:n+10, 2)      # indices, i might be smaller than j!
        v1, v2 = sort(rand(0:n, 2)) # values to be inserted; always: v1 <= v2 !

        # first compare the non mutating functions
        compare(l, getindex, i)
        compare(l, getindex, i:j)
        compare(l, last)
        compare(l, first)
        compare(v, l, reverse)
        compare(v, l, isempty)
        compare(v, l, length)
        compare(v, l, collect)
        compare(v, l, map, identity)
        compare(v, l, (x, y) -> filter(y, x), iseven)
        compare(v, l, (x, y) -> filter(y, x), false)
        compare(v, l, (x, y) -> filter(y, x), true)
        compare(v, l, copy)

        compare!(v, l, splice!, i)
        compare!(v, l, splice!, i:j)
        compare!(v, l, splice!, i, v1)
        compare!(v, l, splice!, i:j, v1:v2)
        compare!(l, setindex!, i, v1)
        compare!(v, l, pop!)
        compare!(v, l, popfirst!)
        compare!(v, l, popat!, i)
        compare!(v, l, (x, y) -> filter!(y, x), isodd)
        compare!(v, l, reverse!)
        compare!(v, l, push!, i)
        compare!(v, l, pushfirst!, i)
        compare!(v, l, append!, rand(Int, rand(0:3))...)
        compare!(v, l, prepend!, rand(Int, rand(0:3))...)
        compare!(v, l, deleteat!, i)
        compare!(v, l, deleteat!, i:j)
        compare!(v, l, empty!)
    end
end