"""
    CircularVectorBuffer{T}(n)

The CircularVectorBuffer type implements a circular buffer of fixed capacity
where new items are pushed to the back of the list, overwriting values
in a circular fashion.

Allocate a buffer of elements of type `T` with maximum capacity `n`.
"""
mutable struct CircularVectorBuffer{T} <: AbstractMatrix{T}
    capacity::Int
    first::Int
    length::Int
    buffer::Matrix{T}

    CircularVectorBuffer{T}(capacity::Int, second_dim::Int) where {T} = new{T}(capacity, 1, 0, Matrix{T}(undef, capacity, second_dim))
end

"""
    empty!(cb)

Reset the buffer.
"""
function Base.empty!(cb::CircularVectorBuffer)
    cb.length = 0
    cb
end

Base.@propagate_inbounds function _buffer_index_checked(cb::CircularVectorBuffer, i::Int)
    @boundscheck if i < 1 || i > cb.length
        throw(BoundsError(cb, i))
    end
    _buffer_index(cb, i)
end

@inline function _buffer_index(cb::CircularVectorBuffer, i::Int)
    n = cb.capacity
    idx = cb.first + i - 1
    if idx > n
        idx - n
    else
        idx
    end
end

"""
    cb[i]

Get the i-th element of CircularVectorBuffer.

* `cb[1]` to get the element at the front
* `cb[end]` to get the element at the back
"""
@inline Base.@propagate_inbounds function Base.getindex(cb::CircularVectorBuffer, i::Int, j::Int)
    cb.buffer[_buffer_index_checked(cb, i), j]
end

"""
    cb[i] = data

Store data to the i-th element of CircularVectorBuffer.
"""
@inline Base.@propagate_inbounds function Base.setindex!(cb::CircularVectorBuffer, data, i::Int, j::Int)
    cb.buffer[_buffer_index_checked(cb, i), j] = data
    cb
end

"""
    pop!(cb)

Remove the element at the back.
"""
@inline function Base.pop!(cb::CircularVectorBuffer)
    if cb.length == 0
        throw(ArgumentError("array must be non-empty"))
    end
    i = _buffer_index(cb, cb.length)
    cb.length -= 1
    cb.buffer[i, :]
end

"""
    push!(cb)

Add an element to the back and overwrite front if full.
"""
@inline function Base.push!(cb::CircularVectorBuffer, data)
    # if full, increment and overwrite, otherwise push
    if cb.length == cb.capacity
        cb.first = (cb.first == cb.capacity ? 1 : cb.first + 1)
    else
        cb.length += 1
    end
    cb.buffer[_buffer_index(cb, cb.length), :] = data
    cb
end

"""
    popfirst!(cb)

Remove the first item (at the back) from CircularVectorBuffer.
"""
function popfirst!(cb::CircularVectorBuffer)
    if cb.length == 0
        throw(ArgumentError("array must be non-empty"))
    end
    i = cb.first
    cb.first = (cb.first + 1 > cb.capacity ? 1 : cb.first + 1)
    cb.length -= 1
    cb.buffer[i, :]
end

"""
    pushfirst!(cb, data)

Insert one or more items at the beginning of CircularVectorBuffer
and overwrite back if full.
"""
function pushfirst!(cb::CircularVectorBuffer, data)
    # if full, decrement and overwrite, otherwise pushfirst
    cb.first = (cb.first == 1 ? cb.capacity : cb.first - 1)
    if cb.length < cb.capacity
        cb.length += 1
    end
    cb.buffer[cb.first, :] = data
    cb
end

"""
    append!(cb, datavec)

Push at most last `capacity` items.
"""
function Base.append!(cb::CircularVectorBuffer, datamat::AbstractMatrix)
    # push at most last `capacity` items
    n = size(datamat, 1)
    for i in max(1, n-capacity(cb)+1):n
        push!(cb, datamat[i, :])
    end
    cb
end

"""
    fill!(cb, data)

Grows the buffer up-to capacity, and fills it entirely.
It doesn't overwrite existing elements.
"""
function Base.fill!(cb::CircularVectorBuffer, data)
    for i in 1:capacity(cb)-cb.length
        push!(cb, data)
    end
    cb
end

"""
    length(cb)

Return the number of elements currently in the buffer.
"""
Base.length(cb::CircularVectorBuffer) = cb.length * size(cb.buffer, 2)

"""
    size(cb)

Return a tuple with the size of the buffer.
"""
Base.size(cb::CircularVectorBuffer) = (cb.length, size(cb.buffer, 2))

Base.convert(::Type{Array}, cb::CircularVectorBuffer{T}) where {T} = T[x for x in cb]

"""
    isempty(cb)

Test whether the buffer is empty.
"""
Base.isempty(cb::CircularVectorBuffer) = cb.length == 0

""""
    capacity(cb)

Return capacity of CircularVectorBuffer.
"""
capacity(cb::CircularVectorBuffer) = cb.capacity

"""
    isfull(cb)

Test whether the buffer is full.
"""
isfull(cb::CircularVectorBuffer) = cb.length == cb.capacity
