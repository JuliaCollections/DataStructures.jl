"""
    CircularBuffer{T}(v,n::Int)

The CircularBuffer type implements a circular buffer of fixed capacity
where new items are pushed to the back of the list, overwriting values
in a circular fashion.

Allocate a buffer of elements of type `T`  containing items `v` with maximum capacity `n`.
If no capacity is provided the capacity is the number of elements in `v`
"""
mutable struct CircularBuffer{T} <: AbstractVector{T}
    capacity::Int
    first::Int
    length::Int
    buffer::Vector{T}

    function CircularBuffer{T}(f,len,buf) where {T}
        f <= length(buf) || throw(ArgumentError("Value of 'first' must be inbounds of buffer"))
        len <= length(buf) || throw(ArgumentError("Value of 'length' must be <= length of buffer"))
        return new{T}(length(buf), f, len, buf)
    end

    # Convert any `Integer` to whatever `Int` is on the relevant machine
    CircularBuffer{T}(f::Integer, len::Integer, buf::Integer) where {T} = CircularBuffer{T}(Int(f), Int(len), Int(buf))
end

function CircularBuffer{T}(iter, capacity::Integer) where {T}
    vec = copyto!(Vector{T}(undef,capacity), iter)
    CircularBuffer{T}(1, length(iter),vec)
end

CircularBuffer(capacity::Integer) = CircularBuffer{Any}(capacity)

CircularBuffer{T}(capacity::Integer) where {T} = CircularBuffer{T}(T[],capacity)

CircularBuffer(iter,capacity::Integer) =  CircularBuffer{eltype(iter)}(iter,capacity)

function CircularBuffer{T}(iter) where {T}
  vec = reshape(collect(T,iter),:) 
  CircularBuffer{T}(1, length(vec), vec)
end

CircularBuffer(iter) = CircularBuffer{eltype(iter)}(iter)

"""
    empty!(cb::CircularBuffer)

Reset the buffer.
"""
function Base.empty!(cb::CircularBuffer)
    cb.length = 0
    return cb
end

Base.@propagate_inbounds function _buffer_index_checked(cb::CircularBuffer, i::Int)
    @boundscheck if i < 1 || i > cb.length
        throw(BoundsError(cb, i))
    end
    _buffer_index(cb, i)
end

@inline function _buffer_index(cb::CircularBuffer, i::Int)
    n = cb.capacity
    idx = cb.first + i - 1
    return ifelse(idx > n, idx - n, idx)
end

"""
    cb[i]

Get the i-th element of CircularBuffer.

* `cb[1]` to get the element at the front
* `cb[end]` to get the element at the back
"""
@inline Base.@propagate_inbounds function Base.getindex(cb::CircularBuffer, i::Int)
    cb.buffer[_buffer_index_checked(cb, i)]
end

"""
    cb[i] = data

Store data to the `i`-th element of `CircularBuffer`.
"""
@inline Base.@propagate_inbounds function Base.setindex!(cb::CircularBuffer, data, i::Int)
    cb.buffer[_buffer_index_checked(cb, i)] = data
    return cb
end

"""
    pop!(cb::CircularBuffer)

Remove the element at the back.
"""
@inline function Base.pop!(cb::CircularBuffer)
    @boundscheck (cb.length == 0) && throw(ArgumentError("array must be non-empty"))
    i = _buffer_index(cb, cb.length)
    cb.length -= 1
    return @inbounds cb.buffer[i]
end

"""
    push!(cb::CircularBuffer, data)

Add an element to the back and overwrite front if full.
"""
@inline function Base.push!(cb::CircularBuffer{T}, data) where T

    # As per the behaviour of Base.push!
    data_converted = convert(T, data)

    # if full, increment and overwrite, otherwise push
    if cb.length == cb.capacity
        cb.first = (cb.first == cb.capacity ? 1 : cb.first + 1)
    else
        cb.length += 1
    end
    @inbounds cb.buffer[_buffer_index(cb, cb.length)] = data_converted
    return cb
end

"""
    popfirst!(cb::CircularBuffer)

Remove the element from the front of the `CircularBuffer`.
"""
function Base.popfirst!(cb::CircularBuffer)
    @boundscheck (cb.length == 0) && throw(ArgumentError("array must be non-empty"))
    i = cb.first
    cb.first = (cb.first + 1 > cb.capacity ? 1 : cb.first + 1)
    cb.length -= 1
    return @inbounds cb.buffer[i]
end

"""
    pushfirst!(cb::CircularBuffer, data)

Insert one or more items at the beginning of CircularBuffer
and overwrite back if full.
"""
function Base.pushfirst!(cb::CircularBuffer, data)
    # if full, decrement and overwrite, otherwise pushfirst
    cb.first = (cb.first == 1 ? cb.capacity : cb.first - 1)
    if length(cb) < cb.capacity
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
Base.length(cb::CircularBuffer) = cb.length

"""
    size(cb::CircularBuffer)

Return a tuple with the size of the buffer.
"""
Base.size(cb::CircularBuffer) = (length(cb),)

"""
    isempty(cb::CircularBuffer)

Test whether the buffer is empty.
"""
Base.isempty(cb::CircularBuffer) = cb.length == 0

""""
    capacity(cb::CircularBuffer)

Return capacity of CircularBuffer.
"""
capacity(cb::CircularBuffer) = cb.capacity

# Base might define `isfull` from julia 1.11 onwards, see julia PR #53159
if isdefined(Base, :isfull)
    import Base: isfull
end

"""
    isfull(cb::CircularBuffer)

Test whether the buffer is full.
"""
isfull(cb::CircularBuffer) = length(cb) == cb.capacity

"""
    first(cb::CircularBuffer)

Get the first element of CircularBuffer.
"""
Base.@propagate_inbounds function Base.first(cb::CircularBuffer)
    @boundscheck (cb.length == 0) && throw(BoundsError(cb, 1))
    return cb.buffer[cb.first]
end
"""
    last(cb::CircularBuffer)

Get the last element of CircularBuffer.
"""
Base.@propagate_inbounds function Base.last(cb::CircularBuffer)
    @boundscheck (cb.length == 0) && throw(BoundsError(cb, 1))
    return cb.buffer[_buffer_index(cb, cb.length)]
end

"""
    resize!(cb::CircularBuffer, n)

Resize CircularBuffer to the maximum capacity of n elements.
If n is smaller than the current buffer length, the first n elements will be retained.
"""
function Base.resize!(cb::CircularBuffer, n::Integer)
    if n != capacity(cb)
        buf_new = Vector{eltype(cb)}(undef, n)
        len_new = min(length(cb), n)
        for i in 1:len_new
            @inbounds buf_new[i] = cb[i]
        end

        cb.capacity = n
        cb.first = 1
        cb.length = len_new
        cb.buffer = buf_new
    end
    return cb
end
