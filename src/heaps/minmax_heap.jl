################################################
#
# minmax heap type and constructors
#
################################################

mutable struct BinaryMinMaxHeap{T} <: AbstractMinMaxHeap{T}
    valtree::Vector{T}

    BinaryMinMaxHeap{T}() where {T} = new{T}(Vector{T}())

    function BinaryMinMaxHeap{T}(xs::AbstractVector{T}) where {T}
        valtree = _make_binary_minmax_heap(xs)
        new{T}(valtree)
    end
end

BinaryMinMaxHeap(xs::AbstractVector{T}) where T = BinaryMinMaxHeap{T}(xs)

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
    return valtree
end

function _minmax_heap_bubble_up!(A::AbstractVector, i::Integer)
    if on_minlevel(i)
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
end

function _minmax_heap_bubble_up!(A::AbstractVector, i::Integer, o::Ordering, x=A[i])
    if hasgrandparent(i)
        gparent = hparent(hparent(i))
        if lt(o, x, A[gparent])
            A[i] = A[gparent]
            A[gparent] = x
            _minmax_heap_bubble_up!(A, gparent, o)
        end
    end
end

function _minmax_heap_trickle_down!(A::AbstractVector, i::Integer)
    if on_minlevel(i)
        _minmax_heap_trickle_down!(A, i, Forward)
    else
        _minmax_heap_trickle_down!(A, i, Reverse)
    end
end

function _minmax_heap_trickle_down!(A::AbstractVector, i::Integer, o::Ordering, x=A[i])

    if haschildren(i, A)
        # get the index of the extremum (min or max) descendant
        extremum = o === Forward ? minimum : maximum
        _, m = extremum((A[j], j) for j in children_and_grandchildren(length(A), i))

        if isgrandchild(m, i)
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
@inline on_minlevel(i) = level(i) % 2 == 0
@inline haschildren(i, A) = lchild(i) ≤ length(A)
@inline isgrandchild(j, i) = j > rchild(i)
@inline hasgrandparent(i) = i ≥ 4

"""
    children_and_grandchildren(maxlen, i)

Return the indices of all children and grandchildren of
position `i`.
"""
function children_and_grandchildren(maxlen::T, i::T) where {T <: Integer}
    _children_and_grandchildren = T[]
    for child in children(i)
        for desc in (child, lchild(child), rchild(child))
            if desc ≤ maxlen
                push!(_children_and_grandchildren, desc)
            end
        end
    end
    return _children_and_grandchildren
end

"""
    is_minmax_heap(h::AbstractVector) -> Bool

Return `true` if `A` is a min-max heap. A min-max heap is a
heap where the minimum element is the root and the maximum
element is a child of the root.
"""
function is_minmax_heap(A::AbstractVector)

    for i in 1:length(A)
        if on_minlevel(i)
            # check that A[i] < children A[i]
            #    and grandchildren A[i]
            for j in children_and_grandchildren(length(A), i)
                A[i] ≤ A[j] || return false
            end
        else
            # max layer
            for j in children_and_grandchildren(length(A), i)
                A[i] ≥ A[j] || return false
            end
        end
    end
    return true
end

################################################
#
# interfaces
#
################################################

Base.length(h::BinaryMinMaxHeap) = length(h.valtree)

Base.isempty(h::BinaryMinMaxHeap) = isempty(h.valtree)

"""
    pop!(h::BinaryMinMaxHeap) = popmin!(h)
"""
@inline Base.pop!(h::BinaryMinMaxHeap) = popmin!(h)

function Base.sizehint!(h::BinaryMinMaxHeap, s::Integer)
    sizehint!(h.valtree, s)
    return h
end

"""
    popmin!(h::BinaryMinMaxHeap) -> min

Remove the minimum value from the heap.
"""
function popmin!(h::BinaryMinMaxHeap)
    valtree = h.valtree
    !isempty(valtree) || throw(ArgumentError("heap must be non-empty"))
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
    !isempty(valtree) || throw(ArgumentError("heap must be non-empty"))
    @inbounds x, i = maximum(((valtree[j], j) for j in 1:min(length(valtree), 3)))
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


function Base.push!(h::BinaryMinMaxHeap, v)
    valtree = h.valtree
    push!(valtree, v)
    _minmax_heap_bubble_up!(valtree, length(valtree))
end

"""
    first(h::BinaryMinMaxHeap)

Get the first (minimum) of the heap.
"""
@inline Base.first(h::BinaryMinMaxHeap) = minimum(h)

@inline function Base.minimum(h::BinaryMinMaxHeap)
    valtree = h.valtree
    !isempty(h) || throw(ArgumentError("heap must be non-empty"))
    return @inbounds h.valtree[1]
end

@inline function Base.maximum(h::BinaryMinMaxHeap)
    valtree = h.valtree
    !isempty(h) || throw(ArgumentError("heap must be non-empty"))
    return @inbounds maximum(valtree[1:min(end, 3)])
end

Base.empty!(h::BinaryMinMaxHeap) = (empty!(h.valtree); h)


"""
    popall!(h::BinaryMinMaxHeap, ::Ordering = Forward)

Remove and return all the elements of `h` according to
the given ordering. Default is `Forward` (smallest to
largest).
"""
popall!(h::BinaryMinMaxHeap) = popall!(h, Forward)
popall!(h::BinaryMinMaxHeap, ::ForwardOrdering) = popmin!(h, length(h))
popall!(h::BinaryMinMaxHeap, ::ReverseOrdering) = popmax!(h, length(h))
