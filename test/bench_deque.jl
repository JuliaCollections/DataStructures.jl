# benchmark of deque

using DataStructures

# push_back

v = Int[]
q = Dequeue{Int}()

push!(v, 0)
t1 = @elapsed for i = 1 : 10^7
    push!(v, i)
end

push_back!(q, 0)
t2 = @elapsed for i = 1 : 10^7
    push_back!(q, i)
end

println("push back 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Dequeue:  elapsed = %8.4fs\n", t2)

# push_front

v = Int[]
q = Dequeue{Int}()

unshift!(v, 0)
t1 = @elapsed for i = 1 : 10^7
    unshift!(v, i)
end

push_front!(q, 0)
t2 = @elapsed for i = 1 : 10^7
    push_front!(q, i)
end

println("push front 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Dequeue:  elapsed = %8.4fs\n", t2)
