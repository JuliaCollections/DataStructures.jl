"""
New items are pushed to the back of the list, overwriting values in a circular fashion.
"""
mutable struct CircularBuffer{T} <: AbstractVector{T}
    capacity::Int
    first::Int
    buffer::Vector{T}

    CircularBuffer{T}(capacity::Int) where {T} = new{T}(capacity, 1, T[])
end

function _buffer_index(cb::CircularBuffer, i::Int)
    n = length(cb)
    if i < 1 || i > n
        throw(BoundsError("CircularBuffer out of range. cb=$cb i=$i"))
    end
    idx = cb.first + i - 1
    if idx > n
        idx - n
    else
        idx
    end
end

function getindex(cb::CircularBuffer, i::Int)
    cb.buffer[_buffer_index(cb, i)]
end

function setindex!(cb::CircularBuffer, data, i::Int)
    cb.buffer[_buffer_index(cb, i)] = data
    cb
end

function push!(cb::CircularBuffer, data)
    # if full, increment and overwrite, otherwise push
    if length(cb) == cb.capacity
        cb.first = (cb.first == cb.capacity ? 1 : cb.first + 1)
        cb[length(cb)] = data
    else
        push!(cb.buffer, data)
    end
    cb
end

function unshift!(cb::CircularBuffer, data)
    # if full, decrement and overwrite, otherwise unshift
    if length(cb) == cb.capacity
        cb.first = (cb.first == 1 ? cb.capacity : cb.first - 1)
        cb[1] = data
    else
        unshift!(cb.buffer, data)
    end
    cb
end

function append!(cb::CircularBuffer, datavec::AbstractVector)
    # push at most `capacity` items
    n = length(datavec)
    for i in max(1, n-capacity(cb)+1):n
        push!(cb, datavec[i])
    end
    cb
end

length(cb::CircularBuffer) = length(cb.buffer)
size(cb::CircularBuffer) = (length(cb),)
convert(::Type{Array}, cb::CircularBuffer{T}) where {T} = T[x for x in cb]
isempty(cb::CircularBuffer) = isempty(cb.buffer)

capacity(cb::CircularBuffer) = cb.capacity
isfull(cb::CircularBuffer) = length(cb) == cb.capacity
