"""
New items are pushed to the back of the list, overwriting values in a circular fashion.
"""
type CircularBuffer{T, N} <: AbstractArray{T, N}
    capacity::Int
    first::Int
    buffer::Array{T, N}
    used::Int
    colons::Vector{Colon}

    function CircularBuffer(capacity::Int, others_dims...)
        a = Array{T, N}(capacity, others_dims...)
        colons = Vector{Colon}(N - 1)
        new(capacity, 1, a, 0, colons)
    end
end

function CircularBuffer(T, capacity::Int, others_dims...)
    N = length(others_dims) + 1
    CircularBuffer{T,N}(capacity::Int, others_dims...)
end

function _buffer_index(cb::CircularBuffer, i::Int)
    n = length(cb)
    if i < 1 || i > n
        throw(BoundsError("CircularBuffer out of range. cb=$cb i=$i"))
    end
    idx = mod1(cb.first + i - 1, n)
end

function Base.getindex(cb::CircularBuffer, i::Int)
    cb.buffer[_buffer_index(cb, i), cb.colons...]
end

function Base.setindex!(cb::CircularBuffer, data, i::Int)
    cb.buffer[_buffer_index(cb, i), cb.colons...] = data
    cb
end

function Base.push!(cb::CircularBuffer, data)
    # if full, increment and overwrite, otherwise push
    if length(cb) == cb.capacity
        cb.first = (cb.first == cb.capacity ? 1 : cb.first + 1)
        cb[cb.capacity] = data
    else
        cb.buffer[cb.used + 1, cb.colons...] = data
        cb.used += 1
    end
    cb
end

function Base.append!(cb::CircularBuffer, datavec::AbstractVector)
    # push at most `capacity` items
    n = length(datavec)
    for i in max(1, n-capacity(cb)+1):n
        push!(cb, datavec[i])
    end
    cb
end

Base.ndims(cb::CircularBuffer) = ndims(cb.buffer)
Base.length(cb::CircularBuffer) = cb.used
Base.convert{T}(::Type{Array}, cb::CircularBuffer{T}) = T[x for x in cb]
Base.isempty(cb::CircularBuffer) = cb.used == 0
function Base.size(cb::CircularBuffer)
    (length(cb), size(cb.buffer)[2:end]...)
end


capacity(cb::CircularBuffer) = cb.capacity
isfull(cb::CircularBuffer) = length(cb) == cb.capacity