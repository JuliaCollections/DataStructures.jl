# FIFO queue

"""
    Queue{T}([blksize::Integer=1024])

Create a `Queue` object containing elements of type `T`.

Needs to have mutable removed but need think about this a little more
"""
mutable struct Queue{T}
    store::Deque{T}
end

Queue{T}() where {T} = Queue(Deque{T}())
Queue{T}(blksize::Integer) where {T} = Queue(Deque{T}(blksize))

isempty(s::Queue) = isempty(s.store)
length(s::Queue) = length(s.store)
Base.eltype(::Type{Queue{T}}) where T = T

first(s::Queue) = first(s.store)
last(s::Queue) = last(s.store)

"""
    enqueue!(s::Queue, x)

Inserts the value `x` to the end of the queue `s`.
"""
function enqueue!(s::Queue, x)
    y = Queue(s.store)
    return push!(y.store, x)
end

"""
    dequeue!(s::Queue)

Removes an element from the front of the queue `s` and returns it.
"""
function dequeue!(s::Queue)
    y = Queue(s.store)
    first = pop!(s.store)
    s.store = y.store
    return first

"""
Tried to make above and below functions immutable but not too sure!
"""
function empty!(s::Queue)
    y = Queue(s.store)
    return (empty!(y.store); y)


# Iterators

iterate(q::Queue, s...) = iterate(q.store, s...)

reverse_iter(q::Queue) = reverse_iter(q.store)

==(x::Queue, y::Queue) = x.store == y.store
