"""
    CircularBuffer{T}(n)

The CircularBuffer type implements a circular buffer of fixed capacity
where new items are pushed to the back of the list, overwriting values
in a circular fashion.

Allocate a buffer of elements of type `T` with maximum capacity `n`.
"""
mutable struct CircularBuffer{T} <: AbstractVector{T}
    capacity::Int
    first::Int
    length::Int
    buffer::Vector{T}

    CircularBuffer{T}(capacity::Int) where {T} = new{T}(capacity, 1, 0, Vector{T}(undef, capacity))
end

CircularBuffer(capacity) = CircularBuffer{Any}(capacity)

Base.IndexStyle(::Type{<:CircularBuffer}) = IndexLinear()

"""
    empty!(cb::CircularBuffer)

Reset the buffer.
"""
function Base.empty!(cb::CircularBuffer)
    cb.length = 0
    return cb
end

@inline function _buffer_index(cb::CircularBuffer, i::Int)
    @boundscheck checkbounds(cb, i)
    n = capacity(cb)
    idx = cb.first + i - 1
    return idx > n ? idx - n : idx
end

"""
    cb[i]

Get the i-th element of CircularBuffer.

* `cb[1]` to get the element at the front
* `cb[end]` to get the element at the back
"""
Base.@propagate_inbounds function Base.getindex(cb::CircularBuffer, i::Int)
    j = _buffer_index(cb, i)
    @inbounds return cb.buffer[j]
end

"""
    cb[i] = data

Store data to the `i`-th element of `CircularBuffer`.
"""
Base.@propagate_inbounds function Base.setindex!(cb::CircularBuffer, data, i::Int)
    j = _buffer_index(cb, i)
    @inbounds cb.buffer[j] = data
    return cb
end

"""
    pop!(cb::CircularBuffer)

Remove the element at the back.
"""
function Base.pop!(cb::CircularBuffer)
    # To be consistent with `Base.pop!`, always check for emptiness and throw an
    # `ArgumentError` if empty. We use `checkbounds` here (and in `popfirst!`) instead of
    # `isempty` because benchmarking shows substantially (~30%) improved performance on some
    # machines.
    checkbounds(Bool, cb, 1) || throw(ArgumentError("circular buffer must be non-empty"))
    @inbounds out = last(cb)
    cb.length -= 1
    return out
end

"""
    push!(cb::CircularBuffer, data)

Add an element to the back and overwrite front if full.
"""
function Base.push!(cb::CircularBuffer, data)
    # if full, increment and overwrite, otherwise push
    if isfull(cb)
        cb.first = (cb.first == capacity(cb) ? 1 : cb.first + 1)
    else
        cb.length += 1
    end
    @inbounds cb[length(cb)] = data
    return cb
end

"""
    popfirst!(cb::CircularBuffer)

Remove the element from the front of the `CircularBuffer`.
"""
function popfirst!(cb::CircularBuffer)
    checkbounds(Bool, cb, 1) || throw(ArgumentError("circular buffer must be non-empty"))
    @inbounds out = first(cb)
    cb.first = (cb.first == capacity(cb) ? 1 : cb.first + 1)
    cb.length -= 1
    return out
end

"""
    pushfirst!(cb::CircularBuffer, data)

Insert one or more items at the beginning of CircularBuffer
and overwrite back if full.
"""
function pushfirst!(cb::CircularBuffer, data)
    # if full, decrement and overwrite, otherwise pushfirst
    cb.first = (cb.first == 1 ? capacity(cb) : cb.first - 1)
    if !isfull(cb)
        cb.length += 1
    end
    @inbounds cb.buffer[cb.first] = data
    return cb
end

"""
    append!(cb::CircularBuffer, datavec::AbstractVector)

Push at most last `capacity` items.
"""
function Base.append!(cb::CircularBuffer, datavec::AbstractVector)
    # push at most last `capacity` items
    n = length(datavec)
    for i in max(1, n-capacity(cb)+1):n
        push!(cb, datavec[i])
    end
    return cb
end

"""
    fill!(cb::CircularBuffer, data)

Grows the buffer up-to capacity, and fills it entirely.
It doesn't overwrite existing elements.
"""
function Base.fill!(cb::CircularBuffer, data)
    for i in 1:capacity(cb)-length(cb)
        push!(cb, data)
    end
    return cb
end

"""
    length(cb::CircularBuffer)

Return the number of elements currently in the buffer.
"""
Base.length

"""
    size(cb::CircularBuffer)

Return a tuple with the size of the buffer.
"""
Base.size(cb::CircularBuffer) = (cb.length,)

"""
    isempty(cb::CircularBuffer)

Test whether the buffer is empty.
"""
Base.isempty

""""
    capacity(cb::CircularBuffer)

Return capacity of CircularBuffer.
"""
capacity(cb::CircularBuffer) = cb.capacity

"""
    isfull(cb::CircularBuffer)

Test whether the buffer is full.
"""
isfull(cb::CircularBuffer) = length(cb) == capacity(cb)

"""
    first(cb::CircularBuffer)

Get the first element of CircularBuffer.
"""
@inline function Base.first(cb::CircularBuffer)
    @boundscheck checkbounds(cb, 1)
    @inbounds return cb.buffer[cb.first]
end

"""
    last(cb::CircularBuffer)

Get the last element of CircularBuffer.
"""
Base.@propagate_inbounds Base.last(cb::CircularBuffer) = cb[end]
