"""
    DiBitVector <: AbstractVector{UInt8}

A bitvector whose elements are two bits wide, allowing
storage of integer values between 0 and 3. Optimized
for performance and memory savings.
"""

const UINT_SZ = sizeof(UInt)   # number of bytes in a system int: 8 or 4
const IDX = UINT_SZ ÷ 2 + 1    # 5 for 64, 3 for 32
const OFFSET = UINT_SZ * 8 - 1 # 63 for 64, 31 for 32
const U32 = UINT_SZ == 4

const FV = U32 ? (UInt32(0), UInt32(0x55555555), UInt32(0xaaaaaaaa), UInt32(0xffffffff)) :
                 (UInt64(0), 0x5555555555555555, 0xaaaaaaaaaaaaaaaa, 0xffffffffffffffff)
                  

mutable struct DiBitVector <: AbstractVector{UInt8}
    data::Vector{UInt}
    len::UInt

    function DiBitVector(n::Integer, v::Integer)
        if !(Int(v) in 0:3)
            throw(ArgumentError("v must be in 0:3"))
        end
        fv = FV[v + 1]
        vec = Vector{UInt}(undef, cld(n, 32))
        fill!(vec, fv)
        return new(vec, n % UInt)
    end
end

@inline checkbounds(D::DiBitVector, n::Integer) =  0 < n ≤ length(D.data) << 5 || throw(BoundsError(D, n))

DiBitVector(n::Integer) = DiBitVector(n, 0)
DiBitVector() = DiBitVector(0, 0)

@inline Base.length(x::DiBitVector) = x.len % Int
@inline Base.size(x::DiBitVector) = (length(x),)

@inline index(n::Integer) = (UInt(n-1) >>> IDX) + 1
@inline offset(n::Integer) = (UInt(n-1) << 1) & OFFSET

@inline function Base.getindex(x::DiBitVector, i::Int)
    @boundscheck checkbounds(x, i)
    return UInt8((@inbounds x.data[index(i)] >>> offset(i)) & 3)
end

@inline function unsafe_setindex!(x::DiBitVector, v::UInt, i::Int)
    bits = @inbounds x.data[index(i)]
    bits &= ~(UInt(3) << offset(i))
    bits |= convert(UInt, v) << offset(i)
    @inbounds x.data[index(i)] = bits
end
    
@inline function Base.setindex!(x::DiBitVector, v::Integer, i::Int)
    v & 3 == v || throw(DomainError("Can only contain 0:3 (tried $v)"))
    @boundscheck checkbounds(x, i)
    unsafe_setindex!(x, convert(UInt, v), i)
end

@inline function Base.push!(x::DiBitVector, v::Integer)
    len = length(x)
    len == length(x.data) << 5 && push!(x.data, zero(UInt))
    x.len = (len + 1) % UInt
    x[len+1] = convert(UInt, v)
    return x
end

@inline function Base.pop!(x::DiBitVector)
    x.len == 0 && throw(ArgumentError("array must be non-empty"))
    v = x[end]
    x.len = (x.len - 1) % UInt
    x.len == (length(x.data) -1) << IDX && pop!(x.data)
    return v
end

@inline zero(x::DiBitVector) = DiBitVector(x.len, 0)
