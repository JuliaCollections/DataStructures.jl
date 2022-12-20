# benchmark of deque

using DataStructures

# push_back

function batch_pushback!(v::Container, n::Int, e::T) where {Container,T}
    for i = 1 : n
        push!(v, e)
    end
end

v = Int[]
q = Deque{Int}()

batch_pushback!(v, 10, 0)
t1 = @elapsed batch_pushback!(v, 10^7, 0)

batch_pushback!(q, 10, 0)
t2 = @elapsed batch_pushback!(q, 10^7, 0)

println("push back 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Deque:    elapsed = %8.4fs\n", t2)


# push_front

function batch_pushfront!(v::Container, n::Int, e::T) where {Container,T}
    for i = 1 : n
        pushfirst!(v, e)
    end
end

v = Int[]
q = Deque{Int}()

batch_pushfront!(v, 10, 0)
t1 = @elapsed batch_pushfront!(v, 10^7, 0)

batch_pushfront!(q, 10, 0)
t2 = @elapsed batch_pushfront!(q, 10^7, 0)

println("push front 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Deque:    elapsed = %8.4fs\n", t2)


# traverse

function traverse(container)
    for e in container
    end
end

traverse(v)
t1 = @elapsed traverse(v)

traverse(q)
t2 = @elapsed traverse(q)

println("traverse 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Deque:    elapsed = %8.4fs\n", t2)

# sum

sum(v)
t1 = @elapsed sum(v)

sum(q)
t2 = @elapsed sum(q)

println("sum 10^7 integers:")
@printf("    Vector:   elapsed = %8.4fs\n", t1)
@printf("    Deque:    elapsed = %8.4fs\n", t2)
