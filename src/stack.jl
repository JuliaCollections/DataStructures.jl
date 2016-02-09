# stacks

type Stack{T}
    store::Deque{T}
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

pop!(s::Stack) = pop!(s.store)

start(st::Stack) = start(reverse_iter(st.store))
next(st::Stack, s) = next(reverse_iter(st.store), s)
done(st::Stack, s) = done(reverse_iter(st.store), s)

reverse_iter{T}(s::Stack{T}) = DequeIterator{T}(s.store)
