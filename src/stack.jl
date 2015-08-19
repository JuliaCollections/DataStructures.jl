# stacks

type Stack{S}   # S is the type of the internal dequeue instance
    store::S
end

Stack{T}(ty::Type{T}) = Stack(Deque{T}())
Stack{T}(ty::Type{T}, blksize::Integer) = Stack(Deque{T}(blksize))

isempty(s::Stack) = isempty(s.store)
length(s::Stack) = length(s.store)

top(s::Stack) = back(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    s
end

#returns a collection that can be used in a for loop
function iter{T}(s::Stack{Deque{T}})
    a = T[]
    for i in s.store
        unshift!(a,i)
    end
    return a
end

pop!(s::Stack) = pop!(s.store)


