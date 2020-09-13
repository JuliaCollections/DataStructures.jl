# FIFO queue

"""
    Queue{T}([blksize::Integer=1024])

Create a `Queue` object containing elements of type `T`.

# Examples
```jldoctest
julia> q = Queue{Int}()
Queue{Int64}(Deque [Int64[]])

julia> push!(q, 1)
Queue{Int64}(Deque [[1]])

julia> x = first(q)
1

julia> length(q)
1

julia> x = popfirst!(q)
1

julia> length(q)
0
```
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
    push!(s::Queue, x)

Inserts the value `x` to the end of the queue `s`.
"""
function Base.push!(s::Queue, x)
    push!(s.store, x)
    return s
end

"""
    popfirst!(s::Queue)

Removes an element from the front of the queue `s` and returns it.
"""
Base.popfirst!(s::Queue) = popfirst!(s.store)

Base.empty!(s::Queue) = (empty!(s.store); s)

# Iterators

Base.iterate(q::Queue, s...) = iterate(q.store, s...)

Iterators.reverse(q::Queue) = Iterators.reverse(q.store)

Base.:(==)(x::Queue, y::Queue) = x.store == y.store
