# Binary heap (non-mutable)

#################################################
#
#   core implementation
#
#################################################

function _heap_bubble_up!(order::Ordering, valtree::Array{T}, i::Int) where {T}
    i0::Int = i
    @inbounds v = valtree[i]

    while i > 1  # nd is not root
        p = i >> 1
        @inbounds vp = valtree[p]

        if lt(order, v, vp)
            # move parent downward
            @inbounds valtree[i] = vp
            i = p
        else
            break
        end
    end

    if i != i0
        @inbounds valtree[i] = v
    end
end

function _heap_bubble_down!(order::Ordering, valtree::Array{T}, i::Int) where {T}
    @inbounds v::T = valtree[i]
    swapped = true
    n = length(valtree)
    last_parent = n >> 1

    while swapped && i <= last_parent
        lc = i << 1
        if lc < n   # contains both left and right children
            rc = lc + 1
            @inbounds lv = valtree[lc]
            @inbounds rv = valtree[rc]
            if lt(order, rv, lv)
                if lt(order, rv, v)
                    @inbounds valtree[i] = rv
                    i = rc
                else
                    swapped = false
                end
            else
                if lt(order, lv, v)
                    @inbounds valtree[i] = lv
                    i = lc
                else
                    swapped = false
                end
            end
        else        # contains only left child
            @inbounds lv = valtree[lc]
            if lt(order, lv, v)
                @inbounds valtree[i] = lv
                i = lc
            else
                swapped = false
            end
        end
    end

    valtree[i] = v
end


function _binary_heap_pop!(order::Ordering, valtree::Array{T}) where {T}
    # extract root
    v = valtree[1]

    if length(valtree) == 1
        empty!(valtree)
    else
        valtree[1] = pop!(valtree)
        if length(valtree) > 1
            _heap_bubble_down!(order, valtree, 1)
        end
    end
    return v
end


function _make_binary_heap(order::Ordering, ty::Type{T}, xs) where {T}
    n = length(xs)
    valtree = copy(xs)
    for i = 2 : n
        _heap_bubble_up!(order, valtree, i)
    end
    return valtree
end


#################################################
#
#   heap type and constructors
#
#################################################

mutable struct BinaryHeap{T,O<:Ordering} <: AbstractHeap{T}
    order::O
    valtree::Vector{T}

    BinaryHeap{T}(order::O) where {T,O<:Ordering} = new{T,O}(order, Vector{T}())

    function BinaryHeap{T}(order::O, xs::AbstractVector{T}) where {T,O<:Ordering}
        valtree = _make_binary_heap(order, T, xs)
        new{T,O}(order, valtree)
    end
end

BinaryHeap(order::Ordering, xs::AbstractVector{T}) where T = BinaryHeap{T}(order, xs)

const BinaryMinHeap{T} = BinaryHeap{T, typeof(Forward)}
const BinaryMaxHeap{T} = BinaryHeap{T, typeof(Reverse)}

BinaryMinHeap{T}() where T = BinaryHeap{T}(Forward)
BinaryMinHeap{T}(xs::AbstractVector{T}) where T = BinaryHeap{T}(Forward, xs)
BinaryMaxHeap{T}() where T = BinaryHeap{T}(Reverse)
BinaryMaxHeap{T}(xs::AbstractVector{T}) where T = BinaryHeap{T}(Reverse, xs)
BinaryMinHeap(xs::AbstractVector{T}) where T = BinaryMinHeap{T}(xs)
BinaryMaxHeap(xs::AbstractVector{T}) where T = BinaryMaxHeap{T}(xs)


#################################################
#
#   interfaces
#
#################################################

length(h::BinaryHeap) = length(h.valtree)

isempty(h::BinaryHeap) = isempty(h.valtree)

function push!(h::BinaryHeap, v)
    valtree = h.valtree
    push!(valtree, v)
    _heap_bubble_up!(h.order, valtree, length(valtree))
    return h
end

function sizehint!(h::BinaryHeap, s::Integer)
    sizehint!(h.valtree, s)
    return h
end

"""
    top(h::BinaryHeap)

Returns the element at the top of the heap `h`.
"""
@inline top(h::BinaryHeap) = h.valtree[1]

pop!(h::BinaryHeap{T}) where {T} = _binary_heap_pop!(h.order, h.valtree)
