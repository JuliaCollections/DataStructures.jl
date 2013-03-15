# stacks

type Stack{S}   # S is the type of the internal dequeue instance
    store::S
end

stack{T}(ty::Type{T}) = Stack(Deque{T}())
stack{T}(ty::Type{T}, blksize::Integer) = Stack(Deque{T}(blksize))

isempty(s::Stack) = isempty(s.store)
length(s::Stack) = length(s.store)

top(s::Stack) = back(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    s
end

pop!(s::Stack) = pop!(s.store)
