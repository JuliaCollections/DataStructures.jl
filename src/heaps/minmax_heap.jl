################################################
#
# minmax heap type and constructors
#
################################################

mutable struct BinaryMinMaxHeap{T} <: AbstractMinMaxHeap{T}
    valtree::Vector{T}
    
    function BinaryMinMaxHeap(xs::AbstractVector{T}) where {T}
        valtree = _make_binary_minmax_heap(xs)
        new{T}(valtree)
    end
end

BinaryMinMaxHeap(vt::Type{T}) where {T} = BinaryMinMaxHeap(Vector{T}())

################################################
#
# core implementation
#
################################################

function _make_binary_minmax_heap(xs)
    valtree = copy(xs)
    for i in length(xs):-1:1
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
                    
    if lchild(i) ≤ length(A)
        # tuple (min(val, j1) max(val, j2))
        ext = extrema((A[j], j) for j in descendants(length(A), i))
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

@inline level(i) = floor(Int, log2(i))
@inline lchild(i) = 2*i
@inline rchild(i) = 2*i+1
@inline children(i) = (lchild(i), rchild(i))
 @inline hparent(i) = i ÷ 2

"""
    descendants(maxlen, i)

Return the indices of all children and grandchildren of
position `i`.
"""
function descendants(maxlen::T, i::T) where {T <: Integer}
    _descendants = T[]
    for child in children(i)
        for desc in (child, lchild(child), rchild(child))
            if desc ≤ maxlen
                push!(_descendants, desc)
            end
        end
    end
    return _descendants
end

"""
    is_minmax_heap(h::AbstractVector) -> Bool

Return `true` if `A` is a min-max heap. A min-max heap is a
heap where the minimum element is the root and the maximum
element is a child of the root.
"""
function is_minmax_heap(A::AbstractVector)

    isheap = true

    for i in 1:length(A)
        if level(i)%2 == 0
            # min layer
            # check that A[i] < children A[i]
            #    and grandchildren A[i]
            for j in descendants(length(A), i)
                isheap &= A[i] ≤ A[j]
            end
        else
            # max layer
            for j in descendants(length(A), i)
                isheap &= A[i] ≥ A[j]
            end
        end
    end
    return isheap
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
    popmin!(h::BinaryMinMaxHeap, k::Integer) -> vals
                        
Remove up to the `k` smallest values from the heap.
"""
@inline function popmin!(h::BinaryMinMaxHeap, k::Integer) 
    return [popmin!(h) for _ in 1:min(length(h), k)]
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

"""
    popmax!(h::BinaryMinMaxHeap, k::Integer) -> vals
                        
Remove up to the `k` largest values from the heap.
"""
@inline function popmax!(h::BinaryMinMaxHeap, k::Integer) 
    return [popmax!(h) for _ in 1:min(length(h), k)]                    
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
@inline top(h::BinaryMinMaxHeap) = minimum(h)

@inline minimum(h::BinaryMinMaxHeap) = h.valtree[1]

function maximum(h::BinaryMinMaxHeap) 
    valtree = h.valtree
    return @inbounds maximum(valtree[1:min(end, 3)])
end
                        
empty!(h::BinaryMinMaxHeap) = (empty!(h.valtree); h)
                        

"""
    popall!(h::BinaryMinMaxHeap, ::Ordering = Forward)
                        
Remove and return all the elements of `h` according to
the given ordering. Default is `Forward` (smallest to 
largest).
"""
popall!(h::BinaryMinMaxHeap) = popall!(h, Forward)
popall!(h::BinaryMinMaxHeap, ::ForwardOrdering) = popmin!(h, length(h))
popall!(h::BinaryMinMaxHeap, ::ReverseOrdering) = popmax!(h, length(h))

