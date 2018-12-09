using Base.Order: lt, Ordering, Forward, Reverse, ForwardOrdering, ReverseOrdering
import Base: length, isempty, empty!, push!, pop!, min, max
import DataStructures: top

################################################
#
# minmax heap type and constructors
#
################################################

abstract type AbstractMinMaxHeap{T} <: AbstractHeap{T} end

mutable struct BinaryMinMaxHeap{T} <: AbstractMinMaxHeap{T}
    valtree::Vector{T}
    
    function BinaryMinMaxHeap{T}() where {T}
        new{T}(Vector{T}())
    end
    
    function BinaryMinMaxHeap{T}(xs) where {T}
        valtree = _make_binary_minmax_heap(T, xs)
        new{T}(valtree)
    end
end

binary_minmax_heap(vt::Type{T}) where {T} = BinaryMinMaxHeap{T}()
binary_minmax_heap(xs::AbstractVector{T}) where {T} = BinaryMinMaxHeap{T}(xs) 


################################################
#
# core implementation
#
################################################

function _make_binary_minmax_heap(vt::Type{T}, xs) where {T}
    n = length(xs)
    valtree = copy(xs)
    for i = n:-1:1
        _minmax_heap_trickle_down!(valtree, i)
    end
    valtree
end

function _minmax_heap_bubble_up!(A::AbstractVector, i::Integer)
    if level(i) % 2 == 0
        # min level
        if i > 1 && A[i] > A[hparent(i)]
            # swap to parent and bubble up max
            tmp = A[i]
            A[i] = A[hparent(i)]
            A[hparent(i)] = tmp
            _minmax_heap_bubble_up!(A, hparent(i), Reverse)
        else
            # bubble up min
            _minmax_heap_bubble_up!(A, i, Forward)
        end
        
    else
        # max level
        if i > 1 && A[i] < A[hparent(i)]
            # swap to parent and bubble up min
            tmp = A[i]
            A[i] = A[hparent(i)]
            A[hparent(i)] = tmp
            _minmax_heap_bubble_up!(A, hparent(i), Forward)
        else
            # bubble up max
            _minmax_heap_bubble_up!(A, i, Reverse)
        end
    end
   return 
end

function _minmax_heap_bubble_up!(A::AbstractVector, i::Integer, o::Ordering, x=A[i])
    gparent = hparent(hparent(i))
    if i > hparent(i) > gparent >= 1
        # i has grandparent
        if lt(o, x, A[gparent])
            A[i] = A[gparent]
            A[gparent] = x
            _minmax_heap_bubble_up!(A, gparent, o)
        end
    end
    return          
end

function _minmax_heap_trickle_down!(A::AbstractVector, i::Integer)
    if level(i) % 2 == 0
        _minmax_heap_trickle_down!(A, i, Forward)
    else
        _minmax_heap_trickle_down!(A, i, Reverse)
    end
    return
end

function _minmax_heap_trickle_down!(A::AbstractVector, i::Integer, o::Ordering, x=A[i])
    N = length(A)
    if lchild(i) ≤ N
        # tuple (min(val, j1) max(val, j2))
        ext = extrema((A[j], j) for j in descendants(N, i))
        m = lt(o, ext[1], ext[2]) ? ext[1][2] : ext[2][2]

        if m ≥ 4*i
            # this is a grandchild
            if lt(o, A[m], A[i])
                A[i] = A[m]
                A[m] = x
                if lt(o, A[hparent(m)], A[m])
                    t = A[m]
                    A[m] = A[hparent(m)]
                    A[hparent(m)] = t
                end
                _minmax_heap_trickle_down!(A, m, o)
            end
        else
            if lt(o, A[m], A[i])
                A[i] = A[m]
                A[m] = x
            end
        end
    end
    return
end
                    
################################################
#
# utilities
#
################################################

@inline level(i) = round(Int, floor(log2(i)))
@inline lchild(i) = 2*i
@inline rchild(i) = 2*i+1
@inline children(i) = [lchild(i), rchild(i)]
@inline hparent(i) = round(Int, floor(i/2))

"""
Return the indices of all children and grandchildren of
position `i`.
"""
function descendants(N::T, i::T) where {T <: Integer}
    _descendants = T[]
    for child in children(i)
        append!(_descendants, [child, lchild(child), rchild(child)])
    end
    return [d for d in _descendants if d ≤ N]
end

"""
    is_minmax_heap(h::AbstractVector) -> Bool

Return `true` if `A` is a min-max heap. A min-max heap is a
heap where the minimum element is the root and the maximum
element is a child of the root.
"""
function is_minmax_heap(A::AbstractVector)

    isheap = true
    N = length(A)

    for i = 1:N
        if level(i)%2 == 0
            # min layer
            # check that A[i] < children A[i]
            #    and grandchildren A[i]
            for j in descendants(N, i)
                isheap &= A[i] ≤ A[j]
            end
        else
            # max layer
            for j in descendants(N, i)
                isheap &= A[i] ≥ A[j]
            end
        end
    end
    isheap
end

################################################
#
# interfaces
#
################################################

length(h::BinaryMinMaxHeap) = length(h.valtree)

isempty(h::BinaryMinMaxHeap) = isempty(h.valtree)

"""
    pop!(h::BinaryMinMaxHeap) = popmin!(h)
"""
@inline pop!(h::BinaryMinMaxHeap) = popmin!(h)

"""
    popmin!(h::BinaryMinMaxHeap) -> min
                        
Remove the minimum value from the heap.
"""
function popmin!(h::BinaryMinMaxHeap)
    valtree = h.valtree
    x = valtree[1]
    y = pop!(valtree)
    if !isempty(valtree)
        valtree[1] = y
        _minmax_heap_trickle_down!(valtree, 1)
    end
    return x
end

"""
    popmax!(h::BinaryMinMaxHeap) -> max
                        
Remove the maximum value from the heap.
"""
function popmax!(h::BinaryMinMaxHeap)
    valtree = h.valtree
    @inbounds x, i = maximum([(valtree[j], j) for j in 1:min(length(valtree), 3)])
    y = pop!(valtree)
    if !isempty(valtree) && i <= length(valtree)
        @inbounds valtree[i] = y
        _minmax_heap_trickle_down!(valtree, i)
    end
    return x    
end

function push!(h::BinaryMinMaxHeap, v)
    valtree = h.valtree        
    push!(valtree, v)
    _minmax_heap_bubble_up!(valtree, length(valtree))
end

"""
    top(h::BinaryMinMaxHeap)
                        
Get the top (minimum) of the heap.
"""
@inline top(h::BinaryMinMaxHeap) = min(h)

@inline min(h::BinaryMinMaxHeap) = h.valtree[1]

function max(h::BinaryMinMaxHeap) 
    valtree = h.valtree
    maxlen = min(length(valtree), 3)
    @inbounds m = maximum([valtree[i] for i in 1:maxlen])
    m
end
                        

"""
    empty!(h::BinaryMinMaxHeap, ::Ordering = Forward)
                        
Remove and return all the elements of `h` according to
the given ordering. Default is `Forward` (smallest to 
largest).
"""
empty!(h::BinaryMinMaxHeap) = empty!(h, Forward)
empty!(h::BinaryMinMaxHeap, ::ForwardOrdering) = ksmallest!(h, length(h))
empty!(h::BinaryMinMaxHeap, ::ReverseOrdering) = klargest!(h, length(h))

@inline function klargest!(h::BinaryMinMaxHeap, k::Integer) 
    return [popmax!(h) for _ in 1:min(length(h), k)]                    
end

@inline function ksmallest!(h::BinaryMinMaxHeap, k::Integer) 
    return [popmin!(h) for _ in 1:min(length(h), k)]
end
