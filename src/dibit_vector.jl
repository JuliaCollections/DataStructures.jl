"""
    DiBitVector(n::Integer, v::Integer)

Create a `DiBitVector` with `n` elements preinitialized to a value `v`
from `0` to `3`, inclusive.

A `DiBitVector` is a vector whose elements are two bits wide, allowing
storage of integer values between 0 and 3. This structure is optimized for
performance and memory savings for large numbers of elements.
"""
mutable struct DiBitVector <: AbstractVector{UInt8}
    data::Vector{UInt64}
    len::UInt

    function DiBitVector(n::Integer, v::Integer)
        if Int(n) < 0
            throw(ArgumentError("n ($n) must be greater than or equal to zero"))
        end
        if !(Int(v) in 0:3)
            throw(ArgumentError("v ($v) must be in 0:3"))
        end
        fv = (0x0000000000000000, 0x5555555555555555,
        0xaaaaaaaaaaaaaaaa, 0xffffffffffffffff)[v + 1]
        vec = Vector{UInt64}(undef, cld(n, 32))
        fill!(vec, fv)
        return new(vec, n % UInt64)
    end
end

@inline Base.checkbounds(D::DiBitVector, n::Integer) =  0 < n ≤ length(D.data) << 5 || throw(BoundsError(D, n))

"""
    DiBitVector(n::Integer)

Create a [`DiBitVector`](@ref) with `n` elements set to `0`.
"""
DiBitVector(n::Integer) = DiBitVector(n, 0)
DiBitVector() = DiBitVector(0, 0)

@inline Base.length(x::DiBitVector) = x.len % Int
@inline Base.size(x::DiBitVector) = (length(x),)

@inline index(n::Integer) = ((n-1) >>> 5) + 1
@inline offset(n::Integer) = ((UInt64(n)-1) << 1) & 63

@inline function Base.getindex(x::DiBitVector, i::Int)
    @boundscheck checkbounds(x, i)
    return UInt8((@inbounds x.data[index(i)] >>> offset(i)) & 3)
end

@inline function Base.unsafe_setindex!(x::DiBitVector, v::UInt64, i::Int)
    bits = @inbounds x.data[index(i)]
    bits &= ~(UInt64(3) << offset(i))
    bits |= convert(UInt64, v) << offset(i)
    @inbounds x.data[index(i)] = bits
end

@inline function Base.setindex!(x::DiBitVector, v::Integer, i::Int)
    v & 3 == v || throw(DomainError("Can only contain 0:3 (tried $v)"))
    @boundscheck checkbounds(x, i)
    unsafe_setindex!(x, convert(UInt64, v), i)
end

@inline function Base.push!(x::DiBitVector, v::Integer)
    len = length(x)
    len == UInt64(length(x.data)) << 5 && push!(x.data, zero(UInt64))
    x.len = (len + 1) % UInt64
    x[len+1] = convert(UInt64, v)
    return x
end

@inline function Base.pop!(x::DiBitVector)
    x.len == 0 && throw(ArgumentError("array must be non-empty"))
    v = x[end]
    x.len = (x.len - 1) % UInt64
    x.len == UInt64((length(x.data) -1)) << 5 && pop!(x.data)
    return v
end

@inline Base.zero(x::DiBitVector) = DiBitVector(x.len, 0)
