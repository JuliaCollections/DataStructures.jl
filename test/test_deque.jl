using DataStructures
using Base.Test
using Compat


# empty dequeue

q = Deque{Int}()
@test length(q) == 0
@test isempty(q)
@test q.blksize == DataStructures.DEFAULT_DEQUEUE_BLOCKSIZE
@test_throws ErrorException front(q)
@test_throws ErrorException back(q)
@test length(sprint(dump,q)) >= 0

@test typeof(deque(Int)) == typeof(Deque{Int}())

q = DataStructures.DequeBlock{Int}(0,0)
@test length(q) == 0
@test capacity(q) == 0
@test isempty(q)
@test length(sprint(show,q)) >= 0

q = Deque{Int}(3)
@test length(q) == 0
@test isempty(q)
@test q.blksize == 3
@test num_blocks(q) == 1
@test_throws ErrorException front(q)
@test_throws ErrorException back(q)
@test isa(collect(q), Vector{Int})
@test collect(q) == Int[]

# push back

n = 10

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

# pop back

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
        @test_throws ErrorException front(q)
        @test_throws ErrorException back(q)
    end

    cq = collect(q)
    @test cq == collect(1:n-i)
end

# push front

q = Deque{Int}(3)

for i = 1 : n
    unshift!(q, i)
    @test length(q) == i
    @test isempty(q) == false
    @test num_blocks(q) == div(i-1, 3) + 1

    @test front(q) == i
    @test back(q) == 1

    cq = collect(q)
    @test isa(cq, Vector{Int})
    @test cq == collect(i:-1:1)
end

# pop front

for i = 1 : n
    x = shift!(q)
    @test length(q) == n - i
    @test isempty(q) == (i == n)
    @test num_blocks(q) == div(n-i-1, 3) + 1
    @test x == n - i + 1

    if !isempty(q)
        @test front(q) == n - i
        @test back(q) == 1
    else
        @test_throws ErrorException front(q)
        @test_throws ErrorException back(q)
    end

    cq = collect(q)
    @test cq == collect(n-i:-1:1)
end

# random operations

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
            unshift!(r, x[i])
            unshift!(q, x[i])
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
            shift!(r)
            shift!(q)
        end
    end

    @test length(q) == length(r)
    @test collect(q) == r
end

# issue #38

q = Deque{Int}(1)
push!(q,1)
@test !isempty(q)
empty!(q)
@test isempty(q)

#empty!
q = Deque{Int}(1)
push!(q,1)
push!(q,2)
@test length(sprint(dump,q)) >= 0
@test typeof(empty!(q)) == typeof(Deque{Int}())
@test isempty(q)
