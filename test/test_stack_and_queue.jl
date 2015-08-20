# test stacks and queues

using DataStructures
using Base.Test

# Stack

s = Stack(Int, 5)
n = 100

@test length(s) == 0
@test isempty(s)
@test_throws ErrorException top(s)
@test_throws ErrorException pop!(s)

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
        @test_throws ErrorException top(s)
    end
    @test isempty(s) == (i == n)
    @test length(s) == n - i
end

#test that iter returns a LIFO collection 

stk = Stack(Int, 10)
#an array to check iteration sequence against
arr = Int64[] 

for i = 1:n
    push!(stk,i)
    push!(arr,i)
end

iterated = iter(stk)
@test(reverse(arr) == iterated)


# Queue

s = Queue(Int, 5)
n = 100

@test length(s) == 0
@test isempty(s)
@test_throws ErrorException front(s)
@test_throws ErrorException back(s)
@test_throws ErrorException dequeue!(s)

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
        @test_throws ErrorException front(s)
        @test_throws ErrorException back(s)
    end
    @test isempty(s) == (i == n)
    @test length(s) == n - i
end

#test that iter returns a FIFO collection 

q = Queue(Int, 10)
#an array to check iteration sequence against
arr = Int64[] 

for i = 1:n
    enqueue!(q,i)
    push!(arr,i)
end

iterated = iter(q)
@test(arr == iterated)
