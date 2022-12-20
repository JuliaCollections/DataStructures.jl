# This file was a part of Julia. License is MIT: http://julialang.org/license

mutable struct IntSet
    bits::BitVector
    inverse::Bool
    IntSet() = new(falses(256), false)
end
IntSet(itr) = union!(IntSet(), itr)

Base.empty(s::IntSet) = IntSet()
Base.copy(s1::IntSet) = copy!(IntSet(), s1)
function Base.copy!(to::IntSet, from::IntSet)
    resize!(to.bits, length(from.bits))
    copyto!(to.bits, from.bits)
    to.inverse = from.inverse
    return to
end
Base.eltype(::Type{IntSet}) = Int
Base.sizehint!(s::IntSet, n::Integer) = (_resize0!(s.bits, n+1); s)

# An internal function for setting the inclusion bit for a given integer n >= 0
@inline function _setint!(s::IntSet, n::Integer, b::Bool)
    idx = n+1
    if idx > length(s.bits)
        !b && return s # setting a bit to zero outside the set's bits is a no-op
        newlen = idx + idx>>1 # This operation may overflow; we want saturation
        _resize0!(s.bits, ifelse(newlen<0, typemax(Int), newlen))
    end
    unsafe_setindex!(s.bits, b, idx) # Use @inbounds once available
    return s
end

# An internal function to resize a bitarray and ensure the newly allocated
# elements are zeroed (will become unnecessary if this behavior changes)
@inline function _resize0!(b::BitVector, newlen::Integer)
    len = length(b)
    resize!(b, newlen)
    len < newlen && @inbounds(b[len+1:newlen] .= false) # resize! gives dirty memory
    return b
end

# An internal function that resizes a bitarray so it matches the length newlen
# Returns a bitvector of the removed elements (empty if none were removed)
function _matchlength!(b::BitArray, newlen::Integer)
    len = length(b)
    len > newlen && return splice!(b, newlen+1:len)
    len < newlen && _resize0!(b, newlen)
    return BitVector()
end

const _intset_bounds_err_msg = "elements of IntSet must be between 0 and typemax(Int)-1"

function Base.push!(s::IntSet, n::Integer)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    _setint!(s, n, !s.inverse)
end
Base.push!(s::IntSet, ns::Integer...) = (for n in ns; push!(s, n); end; s)

function Base.pop!(s::IntSet)
    s.inverse && throw(ArgumentError("cannot pop the last element of complement IntSet"))
    pop!(s, last(s))
end
function Base.pop!(s::IntSet, n::Integer)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    n in s ? (_delete!(s, n); n) : throw(KeyError(n))
end
function Base.pop!(s::IntSet, n::Integer, default)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    n in s ? (_delete!(s, n); n) : default
end
function Base.pop!(f::Function, s::IntSet, n::Integer)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    n in s ? (_delete!(s, n); n) : f()
end
_delete!(s::IntSet, n::Integer) = _setint!(s, n, s.inverse)
Base.delete!(s::IntSet, n::Integer) = n < 0 ? s : _delete!(s, n)
Base.popfirst!(s::IntSet) = pop!(s, first(s))

Base.empty!(s::IntSet) = (fill!(s.bits, false); s.inverse = false; s)
Base.isempty(s::IntSet) = s.inverse ? length(s.bits) == typemax(Int) && all(s.bits) : !any(s.bits)

# Mathematical set functions: union!, intersect!, setdiff!, symdiff!
# When applied to two intsets, these all have a similar form:
# - Reshape s1 to match s2, occasionally grabbing the bits that were removed
# - Use map to apply some bitwise operation across the entire bitvector
#   - These operations use functors to work on the bitvector chunks, so are
#     very efficient... but a little untraditional. E.g., (p > q) => (p & ~q)
# - If needed, append the removed bits back to s1 or invert the array

Base.union(s::IntSet, ns) = union!(copy(s), ns)
Base.union!(s::IntSet, ns) = (for n in ns; push!(s, n); end; s)
function Base.union!(s1::IntSet, s2::IntSet)
    l = length(s2.bits)
    if     !s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif  s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif !s1.inverse &  s2.inverse;  _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = true
    else #= s1.inverse &  s2.inverse=# _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
    end
    s1
end

Base.intersect(s1::IntSet) = copy(s1)
Base.intersect(s1::IntSet, ss...) = intersect(s1, intersect(ss...))
function Base.intersect(s1::IntSet, ns)
    s = IntSet()
    for n in ns
        n in s1 && push!(s, n)
    end
    return s
end
Base.intersect(s1::IntSet, s2::IntSet) = intersect!(copy(s1), s2)
function Base.intersect!(s1::IntSet, s2::IntSet)
    l = length(s2.bits)
    if     !s1.inverse & !s2.inverse;  _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
    elseif  s1.inverse & !s2.inverse;  _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = false
    elseif !s1.inverse &  s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    else #= s1.inverse &  s2.inverse=# e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    end
    return s1
end

Base.setdiff(s::IntSet, ns) = setdiff!(copy(s), ns)
Base.setdiff!(s::IntSet, ns) = (for n in ns; _delete!(s, n); end; s)
function Base.setdiff!(s1::IntSet, s2::IntSet)
    l = length(s2.bits)
    if     !s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(>, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif  s1.inverse & !s2.inverse;  e = _matchlength!(s1.bits, l); map!(|, s1.bits, s1.bits, s2.bits); append!(s1.bits, e)
    elseif !s1.inverse &  s2.inverse;  _resize0!(s1.bits, l);         map!(&, s1.bits, s1.bits, s2.bits)
    else #= s1.inverse &  s2.inverse=# _resize0!(s1.bits, l);         map!(<, s1.bits, s1.bits, s2.bits); s1.inverse = false
    end
    return s1
end

Base.symdiff(s::IntSet, ns) = symdiff!(copy(s), ns)
Base.symdiff!(s::IntSet, ns) = (for n in ns; symdiff!(s, n); end; s)
function Base.symdiff!(s::IntSet, n::Integer)
    0 <= n < typemax(Int) || throw(ArgumentError(_intset_bounds_err_msg))
    val = (n in s) ⊻ !s.inverse
    _setint!(s, n, val)
    return s
end
function Base.symdiff!(s1::IntSet, s2::IntSet)
    e = _matchlength!(s1.bits, length(s2.bits))
    map!(⊻, s1.bits, s1.bits, s2.bits)
    s2.inverse && (s1.inverse = !s1.inverse)
    append!(s1.bits, e)
    return s1
end

function Base.in(n::Integer, s::IntSet)
    idx = n+1
    if 1 <= idx <= length(s.bits)
        unsafe_getindex(s.bits, idx) != s.inverse
    else
        ifelse((idx <= 0) | (idx > typemax(Int)), false, s.inverse)
    end
end

function findnextidx(s::IntSet, i::Int, invert=false)
    if s.inverse ⊻ invert
        # i+1 could rollover causing a BoundsError in findnext/findnextnot
        nextidx = i == typemax(Int) ? 0 : something(findnextnot(s.bits, i+1), 0)
        # Extend indices beyond the length of the bits since it is inverted
        nextidx = nextidx == 0 ? max(i, length(s.bits))+1 : nextidx
    else
        nextidx = i == typemax(Int) ? 0 : something(findnext(s.bits, i+1), 0)
    end
    return nextidx
end

Base.iterate(s::IntSet) = iterate(s, findnextidx(s, 0))

function Base.iterate(s::IntSet, i::Int, invert=false)
    i <= 0 && return nothing
    return (i-1, findnextidx(s, i, invert))
end

# Nextnot iterates through elements *not* in the set
nextnot(s::IntSet, i) = iterate(s, i, true)

function Base.last(s::IntSet)
    l = length(s.bits)
    if s.inverse
        idx = l < typemax(Int) ? typemax(Int) : something(findprevnot(s.bits, l), 0)
    else
        idx = something(findprev(s.bits, l), 0)
    end
    idx == 0 ? throw(ArgumentError("collection must be non-empty")) : idx - 1
end

Base.length(s::IntSet) = (n = sum(s.bits); ifelse(s.inverse, typemax(Int) - n, n))

complement(s::IntSet) = complement!(copy(s))
complement!(s::IntSet) = (s.inverse = !s.inverse; s)

function Base.show(io::IO, s::IntSet)
    print(io, "IntSet([")
    first = true
    for n in s
        if s.inverse && n > 2
            state = nextnot(s, n - 3)
            if state !== nothing && state[2] <= 0
                print(io, ", ..., ", typemax(Int)-1)
                break
            end
         end
        !first && print(io, ", ")
        print(io, n)
        first = false
    end
    print(io, "])")
end

function Base.:(==)(s1::IntSet, s2::IntSet)
    l1 = length(s1.bits)
    l2 = length(s2.bits)
    l1 < l2 && return ==(s2, s1) # Swap so s1 is always equal-length or longer

    # Try to do this without allocating memory or checking bit-by-bit
    if s1.inverse == s2.inverse
        # If the lengths are the same, simply punt to bitarray comparison
        l1 == l2 && return s1.bits == s2.bits
        # Otherwise check the last bit. If equal, we only need to check up to l2
        return findprev(s1.bits, l1) == findprev(s2.bits, l2) &&
               unsafe_getindex(s1.bits, 1:l2) == s2.bits
    else
        # one complement, one not. Could feasibly be true on 32 bit machines
        # Only if all non-overlapping bits are set and overlaps are inverted
        return l1 == typemax(Int) &&
               map!(!, unsafe_getindex(s1.bits, 1:l2)) == s2.bits &&
               (l1 == l2 || all(unsafe_getindex(s1.bits, l2+1:l1)))
    end
end

const hashis_seed = UInt === UInt64 ? 0x88989f1fc7dea67d : 0xc7dea67d
function Base.hash(s::IntSet, h::UInt)
    # Only hash the bits array up to the last-set bit to prevent extra empty
    # bits from changing the hash result
    l = findprev(s.bits, length(s.bits))
    return hash(unsafe_getindex(s.bits, 1:l), h) ⊻ hash(s.inverse) ⊻ hashis_seed
end

Base.issubset(a::IntSet, b::IntSet) = isequal(a, intersect(a,b))
Base.:(<)(a::IntSet, b::IntSet) = (a<=b) && !isequal(a,b)
Base.:(<=)(a::IntSet, b::IntSet) = issubset(a, b)
