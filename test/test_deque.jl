using DataStructures
using Test

# empty dequeue

q = Dequeue{Int}()
@test length(q) == 0
@test isempty(q)
@test block_size(q) == DataStructures.default_dequeue_blocksize

q = Dequeue{Int}(3)
@test length(q) == 0
@test isempty(q) == true
@test block_size(q) == 3
@test num_blocks(q) == 1
@test isa(collect(q), Vector{Int})
@test collect(q) == Int[]

# push back

n = 10

for i = 1 : n
    push_back!(q, i)
    @test length(q) == i
    @test isempty(q) == false
    @test block_size(q) == 3
    @test num_blocks(q) == div(i-1, 3) + 1
    
    @test front(q) == 1
    @test back(q) == i
    
    cq = collect(q)
    @test isa(cq, Vector{Int})
    @test cq == [1:i]
end

# pop back

for i = 1 : n
    x = pop_back!(q)
    @test length(q) == n - i
    @test isempty(q) == (i == n)
    @test block_size(q) == 3
    @test num_blocks(q) == div(n-i-1, 3) + 1
    @test x == n - i + 1
    
    if !isempty(q)
        @test front(q) == 1
        @test back(q) == n - i
    end
    
    cq = collect(q)
    @test cq == [1:n-i]
end

# push front

q = Dequeue{Int}(3)

for i = 1 : n
    push_front!(q, i)
    @test length(q) == i
    @test isempty(q) == false
    @test block_size(q) == 3
    @test num_blocks(q) == div(i-1, 3) + 1
    
    @test front(q) == i
    @test back(q) == 1
    
    cq = collect(q)
    @test isa(cq, Vector{Int})
    @test cq == [i:-1:1]
end

# pop front

for i = 1 : n
    x = pop_front!(q)
    @test length(q) == n - i
    @test isempty(q) == (i == n)
    @test block_size(q) == 3
    @test num_blocks(q) == div(n-i-1, 3) + 1
    @test x == n - i + 1
    
    if !isempty(q)
        @test front(q) == n - i
        @test back(q) == 1
    end
    
    cq = collect(q)
    @test cq == [n-i:-1:1]
end

# random operations

q = Dequeue{Int}(5)
r = Int[]
m = 100

for k = 1 : m
    la = rand(1:20)
    x = rand(1:1000, la)
    
    for i = 1 : la
        if randbool()
            push!(r, x[i])
            push_back!(q, x[i])
        else
            unshift!(r, x[i])
            push_front!(q, x[i])
        end
    end     
    
    @test length(q) == length(r)
    @test collect(q) == r
    
    lr = rand(1:length(r))
    for i = 1 : lr
        if randbool()
            pop!(r)
            pop_back!(q)
        else
            shift!(r)
            pop_front!(q)
        end
    end
    
    @test length(q) == length(r)
    @test collect(q) == r
end


