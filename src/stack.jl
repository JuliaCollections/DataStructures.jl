# stacks

mutable struct Stack{T}
    store::Deque{T}
end

Stack(ty::Type{T}) where {T} = Stack(Deque{T}())
Stack(ty::Type{T}, blksize::Integer) where {T} = Stack(Deque{T}(blksize))

isempty(s::Stack) = isempty(s.store)
length(s::Stack) = length(s.store)

top(s::Stack) = back(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    s
end

pop!(s::Stack) = pop!(s.store)

start(st::Stack) = start(reverse_iter(st.store))
next(st::Stack, s) = next(reverse_iter(st.store), s)
done(st::Stack, s) = done(reverse_iter(st.store), s)

reverse_iter(s::Stack{T}) where {T} = DequeIterator{T}(s.store)
