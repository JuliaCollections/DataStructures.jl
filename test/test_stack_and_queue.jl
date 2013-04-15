# test stacks and queues

using DataStructures
using Base.Test

# Stack

s = stack(Int, 5)
n = 100

@test length(s) == 0
@test isempty(s)

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
    end
    @test isempty(s) == (i == n)
    @test length(s) == n - i
end

# Queue

s = queue(Int, 5)
n = 100

@test length(s) == 0
@test isempty(s)

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
    end
    @test isempty(s) == (i == n)
    @test length(s) == n - i
end
