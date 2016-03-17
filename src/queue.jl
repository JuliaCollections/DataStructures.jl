# FIFO queue

type Queue{T}
    store::Deque{T}
end

"""
    Queue(T[, blksize::Integer=1024])

Create a `Queue` object containing elements of type `T`.
"""
Queue{T}(ty::Type{T}) = Queue(Deque{T}())
Queue{T}(ty::Type{T}, blksize::Integer) = Queue(Deque{T}(blksize))

isempty(s::Queue) = isempty(s.store)
length(s::Queue) = length(s.store)

front(s::Queue) = front(s.store)
back(s::Queue) = back(s.store)

"""
    enqueue!(s::Queue, x)

Inserts the value `x` to the end of the queue `s`.
"""
function enqueue!(s::Queue, x)
    push!(s.store, x)
    s
end

"""
    dequeue!(s::Queue)

Removes an element from the front of the queue `s` and returns it.
"""
dequeue!(s::Queue) = shift!(s.store)

# Iterators

start(q::Queue) = start(q.store)
next(q::Queue, s) = next(q.store, s)
done(q::Queue, s) = done(q.store, s)

reverse_iter(q::Queue) = reverse_iter(q.store)
