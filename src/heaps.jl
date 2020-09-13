# Various heap implementation

###########################################################
#
#   Heap interface specification
#
#   Each heap is associated with a handle type (H), and
#   a value type v.
#
#   Here, the value type must be comparable, and a handle
#   is an object through which one can refer to a specific
#   node of the heap and thus update its value.
#
#   Each heap type must implement all of the following
#   functions. Here, let h be a heap, i be a handle,
#   v be a value and s be a size.
#
#   - length(h)           returns the number of elements
#
#   - isempty(h)          returns whether the heap is
#                         empty
#
#   - push!(h, v)         add a value to the heap
#
#   - sizehint!(h, s)     set size hint to a heap
#
#   - first(h)            return the first (top) value of a heap
#
#   - pop!(h)             removes the first (top) value, and
#                         returns it
#
#  For mutable heaps, it should also support
#
#   - push!(h, v)         adds a value to the heap and
#                         returns a handle to v
#
#   - update!(h, i, v)    updates the value of an element
#                         (referred to by the handle i)
#
#   - delete!(h, i)       deletes the node with
#                         handle i from the heap
#
#   - top_with_handle(h)  return the top value of a heap
#                         and its handle
#
#
###########################################################

# HT: handle type
# VT: value type

abstract type AbstractHeap{VT} end

abstract type AbstractMutableHeap{VT,HT} <: AbstractHeap{VT} end

abstract type AbstractMinMaxHeap{VT} <: AbstractHeap{VT} end

# heap implementations

include("heaps/binary_heap.jl")
include("heaps/mutable_binary_heap.jl")
include("heaps/minmax_heap.jl")

# generic functions

Base.eltype(::Type{<:AbstractHeap{T}}) where T = T

"""
    extract_all!(h)

Return an array of heap elements in sorted order (heap head at first index).

Note that for simple heaps (not mutable or minmax)
sorting the internal array of elements in-place is faster.
"""
function extract_all!(h::AbstractHeap{VT}) where VT
    n = length(h)
    r = Vector{VT}(undef, n)
    for i in 1 : n
        r[i] = pop!(h)
    end
    return r
end

"""
    extract_all_rev!(h)

Return an array of heap elements in reverse sorted order (heap head at last index).

Note that for simple heaps (not mutable or minmax)
sorting the internal array of elements in-place is faster.
"""
function extract_all_rev!(h::AbstractHeap{VT}) where VT
    n = length(h)
    r = Vector{VT}(undef, n)
    for i in 1 : n
        r[n + 1 - i] = pop!(h)
    end
    return r
end

# Array functions using heaps

"""
    nextreme(ord, n, arr)

return an array of the first `n` values of `arr` sorted by `ord`.
"""
function nextreme(ord::Base.Ordering, n::Int, arr::AbstractVector{T}) where T
    if n <= 0
        return T[] # sort(arr)[1:n] returns [] for n <= 0
    elseif n >= length(arr)
        return sort(arr, order = ord)
    end

    rev = Base.ReverseOrdering(ord)

    buffer = heapify(arr[1:n], rev)

    for i = n + 1 : length(arr)
        @inbounds xi = arr[i]
        if Base.lt(rev, buffer[1], xi)
            buffer[1] = xi
            percolate_down!(buffer, 1, rev)
        end
    end

    return sort!(buffer, order = ord)
end

"""
    nlargest(n, arr; kw...)

Return the `n` largest elements of the array `arr`.

Equivalent to:
    sort(arr, kw..., rev=true)[1:min(n, end)]

Note that if `arr` contains floats and is free of NaN values,
then the following alternative may be used to achieve 2x performance:

    DataStructures.nextreme(DataStructures.FasterReverse(), n, arr)

This faster version is equivalent to:

    sort(arr, lt = >)[1:min(n, end)]
"""
function nlargest(n::Int, arr::AbstractVector; lt=isless, by=identity)
    order = Base.ReverseOrdering(Base.ord(lt, by, nothing))
    return nextreme(order, n, arr)
end

"""
    nsmallest(n, arr; kw...)

Return the `n` smallest elements of the array `arr`.

Equivalent to:
    sort(arr; kw...)[1:min(n, end)]

Note that if `arr` contains floats and is free of NaN values,
then the following alternative may be used to achieve 2x performance:

    DataStructures.nextreme(DataStructures.FasterForward(), n, arr)

This faster version is equivalent to:

    sort(arr, lt = <)[1:min(n, end)]
"""
function nsmallest(n::Int, arr::AbstractVector; lt=isless, by=identity)
    order = Base.ord(lt, by, nothing)
    return nextreme(order, n, arr)
end
