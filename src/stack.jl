# stacks

mutable struct Stack{T}
    store::Deque{T}
end

Stack{T}() where {T} = Stack(Deque{T}())
@deprecate Stack(ty::Type{T}) where {T} Stack{T}()

Stack{T}(blksize::Integer) where {T} = Stack(Deque{T}(blksize))
@deprecate Stack(ty::Type{T}, blksize::Integer) where {T} Stack{T}(blksize::Integer)

isempty(s::Stack) = isempty(s.store)
length(s::Stack) = length(s.store)

top(s::Stack) = back(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    s
end

pop!(s::Stack) = pop!(s.store)

empty!(s::Stack) = (empty!(s.store); s)

start(st::Stack) = start(reverse_iter(st.store))
next(st::Stack, s::Tuple) = next(reverse_iter(st.store), s)
done(st::Stack, s::Tuple) = done(reverse_iter(st.store), s)

reverse_iter(s::Stack{T}) where {T} = DequeIterator{T}(s.store)
