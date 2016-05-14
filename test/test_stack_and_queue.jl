# test stacks and queues

# Stack

s = Stack(Int, 5)
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

#test that iter returns a LIFO collection

stk = Stack(Int, 10)
#an array to check iteration sequence against
arr = Int64[]

for i = 1:n
    push!(stk,i)
    push!(arr,i)
end

#test iterator

index = length(arr)
for i in stk
    @test(arr[index] == i)
    index -= 1
end

index = 1
for i in reverse_iter(stk)
    @test(arr[index] == i)
    index += 1
end

@test arr == [i for i in reverse_iter(stk)]
@test reverse(arr) == [i for i in stk]

# Queue

s = Queue(Int, 5)
n = 100

@test isa(s, Queue{Int})
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

#test that iter returns a FIFO collection

q = Queue(Int, 10)
#an array to check iteration sequence against
arr = Int64[]

for i = 1:n
    enqueue!(q,i)
    push!(arr,i)
end

#test iterator

index = 1
for i in q
    @test(arr[index] == i)
    index += 1
end

index = length(arr)
for i in reverse_iter(q)
    @test(arr[index] == i)
    index -= 1
end

@test arr == [i for i in q]
@test reverse(arr) == [i for i in reverse_iter(q)]
