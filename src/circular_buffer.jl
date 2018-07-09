"""
New items are pushed to the back of the list, overwriting values in a circular fashion.
"""
mutable struct CircularBuffer{T} <: AbstractVector{T}
    capacity::Int
    first::Int
    length::Int
    buffer::Vector{T}

    CircularBuffer{T}(capacity::Int) where {T} = new{T}(capacity, 1, 0, Vector{T}(undef, capacity))
end

function Base.empty!(cb::CircularBuffer)
    cb.length = 0
    cb
end

function _buffer_index_checked(cb::CircularBuffer, i::Int)
    if i < 1 || i > cb.length
        throw(BoundsError(cb, i))
    end
    _buffer_index(cb, i)
end

function _buffer_index(cb::CircularBuffer, i::Int)
    n = cb.capacity
    idx = cb.first + i - 1
    if idx > n
        idx - n
    else
        idx
    end
end

function Base.getindex(cb::CircularBuffer, i::Int)
    cb.buffer[_buffer_index_checked(cb, i)]
end

function Base.setindex!(cb::CircularBuffer, data, i::Int)
    cb.buffer[_buffer_index_checked(cb, i)] = data
    cb
end

function Base.pop!(cb::CircularBuffer)
    if cb.length == 0
        throw(ArgumentError("array must be non-empty"))
    end
    i = _buffer_index(cb, cb.length)
    cb.length -= 1
    cb.buffer[i]
end

function Base.push!(cb::CircularBuffer, data)
    # if full, increment and overwrite, otherwise push
    if cb.length == cb.capacity
        cb.first = (cb.first == cb.capacity ? 1 : cb.first + 1)
    else
        cb.length += 1
    end
    cb.buffer[_buffer_index(cb, cb.length)] = data
    cb
end

function Compat.popfirst!(cb::CircularBuffer)
    if cb.length == 0
        throw(ArgumentError("array must be non-empty"))
    end
    i = cb.first
    cb.first = (cb.first + 1 > cb.capacity ? 1 : cb.first + 1)
    cb.length -= 1
    cb.buffer[i]
end

function Compat.pushfirst!(cb::CircularBuffer, data)
    # if full, decrement and overwrite, otherwise pushfirst
    if length(cb) == cb.capacity
        cb.first = (cb.first == 1 ? cb.capacity : cb.first - 1)
        cb[1] = data
    else
        cb.length += 1
        pushfirst!(cb.buffer, data)
    end
    cb
end

function Base.append!(cb::CircularBuffer, datavec::AbstractVector)
    # push at most last `capacity` items
    n = length(datavec)
    for i in max(1, n-capacity(cb)+1):n
        push!(cb, datavec[i])
    end
    cb
end

Base.length(cb::CircularBuffer) = cb.length
Base.size(cb::CircularBuffer) = (length(cb),)
Base.convert(::Type{Array}, cb::CircularBuffer{T}) where {T} = T[x for x in cb]
Base.isempty(cb::CircularBuffer) = cb.length == 0

capacity(cb::CircularBuffer) = cb.capacity
isfull(cb::CircularBuffer) = length(cb) == cb.capacity
