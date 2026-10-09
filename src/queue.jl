# FIFO queue

"""
    Queue{T}() where {T}
    Queue{T}([blksize::Integer=1024])

Create a `Queue` object containing elements of type `T` for First In, First Out (FIFO) access.

# Parameters

- `T::Type` Queue element data type.
- `blksize::Integer=1024` Unrolled linked-list block size (in bytes). Default = 1024.

# Examples
```jldoctest
julia> q_int = Queue{Int64}() # create a queue with int elements
Queue{Int64}(Deque [Int64[]])

julia> q_float = Queue{Float64}() # create a queue with float elements
Queue{Float64}(Deque [Float64[]])
```
"""
mutable struct Queue{T}
    store::Deque{T}
end

Queue{T}() where {T} = Queue(Deque{T}())
Queue{T}(blksize::Integer) where {T} = Queue(Deque{T}(blksize))

"""
    isempty(q::Queue)

Check if queue `q` is empty.
"""
Base.isempty(q::Queue) = isempty(q.store)

"""
    length(q::Queue)

Return the number of elements in queue `q`.
"""
Base.length(q::Queue) = length(q.store)

"""
    eltype(::Type{Queue{T}}) where {T}

Return the type of the elements in the queue.
"""
Base.eltype(::Type{Queue{T}}) where {T} = T

"""
    first(q::Queue)

Get the first item from queue `q`.
"""
Base.first(q::Queue) = first(q.store)

"""
    last(q::Queue)

Get the last element in queue `q`.
"""
Base.last(s::Queue) = last(s.store)

"""
    push!(q::Queue, x)

Inserts the value `x` to the end of the queue `q`.
"""
function Base.push!(q::Queue, x)
    push!(q.store, x)
    return q
end

"""
    popfirst!(q::Queue)

Removes an element from the front of the queue `q` and returns it.
"""
Base.popfirst!(s::Queue) = popfirst!(s.store)

"""
    empty!(q::Queue)

Removes all elements from queue `q`.
"""
Base.empty!(s::Queue) = (empty!(s.store); s)

# Iterators

Base.iterate(q::Queue, s...) = iterate(q.store, s...)

Iterators.reverse(q::Queue) = Iterators.reverse(q.store)

"""
    ==(x::Queue, y::Queue)

Verify if queues `x` and `y` are equivalent in their contents.
"""
Base.:(==)(x::Queue, y::Queue) = x.store == y.store
