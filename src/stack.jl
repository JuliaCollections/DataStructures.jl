# stacks

mutable struct Stack{T}
    store::Deque{T}
end

Stack{T}() where {T} = Stack(Deque{T}())
Stack{T}(blksize::Integer) where {T} = Stack(Deque{T}(blksize))

isempty(s::Stack) = isempty(s.store)
length(s::Stack) = length(s.store)
Base.eltype(::Type{Stack{T}}) where T = T

top(s::Stack) = back(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    s
end

pop!(s::Stack) = pop!(s.store)

empty!(s::Stack) = (empty!(s.store); s)

iterate(st::Stack, s...) = iterate(reverse_iter(st.store), s...)

reverse_iter(s::Stack{T}) where {T} = DequeIterator{T}(s.store)
