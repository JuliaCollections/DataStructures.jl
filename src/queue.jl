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

isempty(s::Queue) = isempty(s.store)
length(s::Queue) = length(s.store)
Base.eltype(::Type{Queue{T}}) where T = T

"""
    first(q::Queue)

Returns the first element of the queue `q`.

Throws an `ArgumentError` if the queue is empty. This check
can be disabled with `@inbounds`.
"""
Base.@propagate_inbounds function first(s::Queue)
    return first(s.store)
end

"""
    last(q::Queue)

Returns the last element of the queue `q`.

Throws an `ArgumentError` if the queue is empty. This check
can be disabled with `@inbounds`.
"""
Base.@propagate_inbounds function last(s::Queue)
    return last(s.store)
end

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

Throws an `ArgumentError` if the queue is empty. This check
can be disabled with `@inbounds`.
"""
Base.@propagate_inbounds function dequeue!(s::Queue)
    return popfirst!(s.store)
end

empty!(s::Queue) = (empty!(s.store); s)

# Iterators

iterate(q::Queue, s...) = iterate(q.store, s...)

reverse_iter(q::Queue) = reverse_iter(q.store)

==(x::Queue, y::Queue) = x.store == y.store
