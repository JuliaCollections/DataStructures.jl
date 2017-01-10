"""
    CircularDeque{T}(n)

Create a double-ended queue of maximum capacity `n`, implemented as a circular buffer. The element type is `T`.
"""
type CircularDeque{T}
    buffer::Vector{T}
    capacity::Int
    n::Int
    first::Int
    last::Int
end

@compat (::Type{CircularDeque{T}}){T}(n::Int) = CircularDeque(Array{T}(n), n, 0, 1, n)

Base.length(D::CircularDeque) = D.n
Base.eltype{T}(::Type{CircularDeque{T}}) = T
capacity(D::CircularDeque) = D.capacity

function Base.empty!(D::CircularDeque)
    D.n = 0
    D.first = 1
    D.last = D.capacity
    D
end

Base.isempty(D::CircularDeque) = D.n == 0

@inline function front(D::CircularDeque)
    @compat @boundscheck D.n > 0 || throw(BoundsError())
    D.buffer[D.first]
end

@inline function back(D::CircularDeque)
    @compat @boundscheck D.n > 0 || throw(BoundsError())
    D.buffer[D.last]
end

@inline function Base.push!(D::CircularDeque, v)
    @compat @boundscheck D.n < D.capacity || throw(BoundsError()) # prevent overflow
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

@inline function Base.unshift!(D::CircularDeque, v)
    @compat @boundscheck D.n < D.capacity || throw(BoundsError())
    D.n += 1
    tmp = D.first - 1
    D.first = ifelse(tmp < 1, D.capacity, tmp)
    @inbounds D.buffer[D.first] = v
    D
end

@inline function Base.shift!(D::CircularDeque)
    v = front(D)
    D.n -= 1
    tmp = D.first + 1
    D.first = ifelse(tmp > D.capacity, 1, tmp)
    v
end

@inline function Base.getindex(D::CircularDeque, i::Integer)
    @compat @boundscheck 1 <= i <= D.n || throw(BoundsError())
    j = D.first + i - 1
    if j > D.capacity
        j -= D.capacity
    end
    @inbounds ret = D.buffer[j]
    ret
end

# Iteration via getindex
Base.start(d::CircularDeque) = 1
Base.next(d::CircularDeque, i) = (d[i], i+1)
Base.done(d::CircularDeque, i) = i == length(d) + 1

function Base.show{T}(io::IO, D::CircularDeque{T})
    print(io, "CircularDeque{$T}([")
    for i = 1:length(D)
        print(io, D[i])
        i < length(D) && print(io, ',')
    end
    print(io, "])")
end
