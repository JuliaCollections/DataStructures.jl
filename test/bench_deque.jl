# benchmark of deque

using DataStructures

# push_back

v = Int[]
q = stack(Int)

push!(v, 0)
t1 = @elapsed for i = 1 : 10^7
    push!(v, i)
end

push!(q, 0)
t2 = @elapsed for i = 1 : 10^7
    push!(q, i)
end

println("push back 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Stack:    elapsed = %8.4fs\n", t2)

# push_front

v = Int[]
q = queue(Int)

unshift!(v, 0)
t1 = @elapsed for i = 1 : 10^7
    unshift!(v, i)
end

enqueue!(q, 0)
t2 = @elapsed for i = 1 : 10^7
    enqueue!(q, i)
end

println("push front 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Queue:    elapsed = %8.4fs\n", t2)
