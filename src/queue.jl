# FIFO queue

"""
    Queue{T}([blksize::Integer=1024])

Create a `Queue` object containing elements of type `T`.
"""
mutable struct Queue{T}
    store::Deque{T}
end

Queue{T}() where {T} = Queue(Deque{T}())
Queue{T}(blksize::Integer) where {T} = Queue(Deque{T}(blksize))

Base.isempty(s::Queue) = isempty(s.store)
Base.length(s::Queue) = length(s.store)
Base.eltype(::Type{Queue{T}}) where T = T

Base.first(s::Queue) = first(s.store)
Base.last(s::Queue) = last(s.store)

"""
    enqueue!(s::Queue, x)

Inserts the value `x` to the end of the queue `s`.
"""
function enqueue!(s::Queue, x)
    push!(s.store, x)
    return s
end

"""
    dequeue!(s::Queue)

Removes an element from the front of the queue `s` and returns it.
"""
dequeue!(s::Queue) = popfirst!(s.store)

Base.empty!(s::Queue) = (empty!(s.store); s)

# Iterators

Base.iterate(q::Queue, s...) = iterate(q.store, s...)

Iterators.reverse(q::Queue) = Iterators.reverse(q.store)

Base.:(==)(x::Queue, y::Queue) = x.store == y.store
