# This was formerly a part of Julia. License is MIT: http://julialang.org/license

# Test dequeing in sorted order.
function test_issorted!(pq::PriorityQueue, priorities)
    last = dequeue!(pq)
    while !isempty(pq)
        value = dequeue!(pq)
        @test priorities[last] <= priorities[value]
        value = last
    end
end

function test_isrequested!(pq::PriorityQueue, keys)
    i = 0
    while !isempty(pq)
        krqst =  keys[i+=1]
        krcvd = dequeue!(pq, krqst)
        @test krcvd == krqst
    end
end

pmax = 1000
n = 10000
r = rand(1:pmax, n)
priorities = Dict(zip(1:n, r))

# building from a dict
pq = PriorityQueue(priorities)
test_issorted!(pq, priorities)

pq = PriorityQueue(priorities)
test_isrequested!(pq, 1:n)

# building from two lists
ks, vs = 1:n, rand(1:pmax, n)
pq = PriorityQueue(ks, vs)
priorities = Dict(zip(ks, vs))
test_issorted!(pq, priorities)
pq = PriorityQueue(ks, vs)
lowpri = findmin(vs)
@test peek(pq)[2] == pq[ks[lowpri[2]]]

# building from two lists - error throw
ks, vs = 1:n+1, rand(1:pmax, n)
@test_throws ArgumentError PriorityQueue(ks, vs)

#enqueue error throw
ks, vs = 1:n, rand(1:pmax, n)
pq = PriorityQueue(ks, vs)
@test_throws ArgumentError enqueue!(pq, 1, 10)

# enqueing via enqueue!
pq = PriorityQueue()
for (k, v) in priorities
    enqueue!(pq, k, v)
end
test_issorted!(pq, priorities)


# enqueing via assign
pq = PriorityQueue()
for (k, v) in priorities
    pq[k] = v
end
test_issorted!(pq, priorities)


# changing priorities
pq = PriorityQueue()
for (k, v) in priorities
    pq[k] = v
end

for _ in 1:n
    k = rand(1:n)
    v = rand(1:pmax)
    pq[k] = v
    priorities[k] = v
end

test_issorted!(pq, priorities)

# dequeuing
pq = PriorityQueue(priorities)
try
    dequeue!(pq, 0)
    error("should have resulted in KeyError")
catch ex
    @test isa(ex, KeyError)
end
@test 10 == dequeue!(pq, 10)
while !isempty(pq)
    @test 10 != dequeue!(pq)
end

priorities2 = Dict(zip('a':'e', 5:-1:1))
pq = PriorityQueue(priorities2)
@test_throws KeyError dequeue_pair!(pq, 'g')
@test dequeue_pair!(pq) == Pair('e', 1)
@test dequeue_pair!(pq, 'b') == Pair('b', 4)
@test length(pq) == 3

# low level heap operations
xs = heapify!([v for v in values(priorities)])
@test issorted([heappop!(xs) for _ in length(priorities)])

xs = heapify(10:-1:1)
@test issorted([heappop!(xs) for _ in 1:10])

xs = Vector{Int}(0)
for priority in values(priorities)
    heappush!(xs, priority)
end
@test issorted([heappop!(xs) for _ in length(priorities)])

@test isheap([1, 2, 3], Base.Order.Forward)
@test !isheap([1, 2, 3], Base.Order.Reverse)
