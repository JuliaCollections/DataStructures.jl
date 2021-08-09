# Binary heap (non-mutable)

include("arrays_as_heaps.jl")

#################################################
#
#   heap type and constructors
#
#################################################

"""
    FasterForward()

FasterForward enables 2x faster float comparison versus Base.ForwardOrdering,
but ordering is undefined if the data contains NaN values.
Enable this higher-performance option by calling the BinaryHeap
constructor instead of the BinaryMinHeap helper constructor.
"""
struct FasterForward <: Base.Ordering end
Base.lt(o::FasterForward, a, b) = a < b

"""
    FasterReverse()

FasterReverse enables 2x faster float comparison versus Base.ReverseOrdering,
but ordering is undefined if the data contains NaN values.
Enable this higher-performance option by calling the BinaryHeap
constructor instead of the BinaryMaxHeap helper constructor.
"""
struct FasterReverse <: Base.Ordering end
Base.lt(o::FasterReverse, a, b) = a > b

mutable struct BinaryHeap{T, O <: Base.Ordering} <: AbstractHeap{T}
    ordering::O
    valtree::Vector{T}

    function BinaryHeap{T}(ordering::Base.Ordering) where T
        new{T, typeof(ordering)}(ordering, Vector{T}())
    end

    function BinaryHeap{T}(ordering::Base.Ordering, xs::AbstractVector) where T
        valtree = heapify(xs, ordering)
        new{T, typeof(ordering)}(ordering, valtree)
    end
end

BinaryHeap(ordering::Base.Ordering, xs::AbstractVector{T}) where T = BinaryHeap{T}(ordering, xs)

# Constructors using singleton order types as type parameters rather than arguments
BinaryHeap{T, O}() where {T, O<:Base.Ordering} = BinaryHeap{T}(O())
BinaryHeap{T, O}(xs::AbstractVector) where {T, O<:Base.Ordering} = BinaryHeap{T}(O(), xs)

# These constructors needed for BinaryMaxHeap, until we have https://github.com/JuliaLang/julia/pull/37822
BinaryHeap{T, DefaultReverseOrdering}() where {T} = BinaryHeap{T}(Base.Reverse)
BinaryHeap{T, DefaultReverseOrdering}(xs::AbstractVector) where {T} = BinaryHeap{T}(Base.Reverse, xs)

# Forward/reverse ordering type aliases
const BinaryMinHeap{T} = BinaryHeap{T, Base.ForwardOrdering}
const BinaryMaxHeap{T} = BinaryHeap{T, DefaultReverseOrdering}

BinaryMinHeap(xs::AbstractVector{T}) where T = BinaryMinHeap{T}(xs)
BinaryMaxHeap(xs::AbstractVector{T}) where T = BinaryMaxHeap{T}(xs)


#################################################
#
#   interfaces
#
#################################################

"""
    length(h::BinaryHeap)

Returns the number of elements in heap `h`.
"""
Base.length(h::BinaryHeap) = length(h.valtree)

"""
    isempty(h::BinaryHeap)

Returns whether the heap `h` is empty.
"""
Base.isempty(h::BinaryHeap) = isempty(h.valtree)

"""
    push!(h::BinaryHeap, value)

Adds the `value` element to the heap `h`.
"""
@inline function Base.push!(h::BinaryHeap, v)
    heappush!(h.valtree, v, h.ordering)
    return h
end

"""
    first(h::BinaryHeap)

Returns the element at the top of the heap `h`.
"""
@inline Base.first(h::BinaryHeap) = h.valtree[1]

"""
    pop!(h::BinaryHeap)

Removes and returns the element at the top of the heap `h`.
"""
Base.pop!(h::BinaryHeap) = heappop!(h.valtree, h.ordering)

"""
    sizehint!(h::BinaryHeap, n::Integer)

Suggest that heap `h` reserve capacity for at least `n` elements. This can improve performance.
"""
function Base.sizehint!(h::BinaryHeap, n::Integer)
    sizehint!(h.valtree, n)
    return h
end
