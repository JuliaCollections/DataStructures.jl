"""
    CircularDeque{T}(n)

Create a double-ended queue of maximum capacity `n`, implemented as a circular buffer. The element type is `T`.
"""
mutable struct CircularDeque{T}
    buffer::Vector{T}
    capacity::Int
    n::Int
    first::Int
    last::Int
end

CircularDeque{T}(n::Int) where {T} = CircularDeque(Vector{T}(undef, n), n, 0, 1, n)

Base.length(D::CircularDeque) = D.n
Base.eltype(::Type{CircularDeque{T}}) where {T} = T
capacity(D::CircularDeque) = D.capacity

function Base.empty!(D::CircularDeque)
    D.n = 0
    D.first = 1
    D.last = D.capacity
    D
end

Base.isempty(D::CircularDeque) = D.n == 0

@inline function front(D::CircularDeque)
    @boundscheck D.n > 0 || throw(BoundsError())
    D.buffer[D.first]
end

@inline function back(D::CircularDeque)
    @boundscheck D.n > 0 || throw(BoundsError())
    D.buffer[D.last]
end

@inline function Base.push!(D::CircularDeque, v)
    @boundscheck D.n < D.capacity || throw(BoundsError()) # prevent overflow
    D.n += 1
    tmp = D.last+1
    D.last = ifelse(tmp > D.capacity, 1, tmp)  # wraparound
    @inbounds D.buffer[D.last] = v
    D
end

@inline function Base.pop!(D::CircularDeque)
    v = back(D)
    D.n -= 1
    tmp = D.last - 1
    D.last = ifelse(tmp < 1, D.capacity, tmp)
    v
end

@inline function pushfirst!(D::CircularDeque, v)
    @boundscheck D.n < D.capacity || throw(BoundsError())
    D.n += 1
    tmp = D.first - 1
    D.first = ifelse(tmp < 1, D.capacity, tmp)
    @inbounds D.buffer[D.first] = v
    D
end

@inline function popfirst!(D::CircularDeque)
    v = front(D)
    D.n -= 1
    tmp = D.first + 1
    D.first = ifelse(tmp > D.capacity, 1, tmp)
    v
end

# getindex sans bounds checking
@inline function _unsafe_getindex(D::CircularDeque, i::Integer)
    j = D.first + i - 1
    if j > D.capacity
        j -= D.capacity
    end
    @inbounds ret = D.buffer[j]
    return ret
end

@inline function Base.getindex(D::CircularDeque, i::Integer)
    @boundscheck 1 <= i <= D.n || throw(BoundsError())
    return _unsafe_getindex(D, i)
end

# Iteration via getindex
@inline function iterate(d::CircularDeque, i = 1)
    i == d.n + 1 ? nothing : (_unsafe_getindex(d, i), i+1)
end

function Base.show(io::IO, D::CircularDeque{T}) where T
    print(io, "CircularDeque{$T}([")
    for i = 1:length(D)
        print(io, D[i])
        i < length(D) && print(io, ',')
    end
    print(io, "])")
end
