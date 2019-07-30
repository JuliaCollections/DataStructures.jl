# Binary heap (non-mutable)

#################################################
#
#   core implementation
#
#################################################

function _heap_bubble_up!(comp::Comp, valtree::Array{T}, i::Int) where {Comp,T}
    i0::Int = i
    @inbounds v = valtree[i]

    while i > 1  # nd is not root
        p = i >> 1
        @inbounds vp = valtree[p]

        if compare(comp, v, vp)
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

function _heap_bubble_down!(comp::Comp, valtree::Array{T}, i::Int) where {Comp,T}
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
            if compare(comp, rv, lv)
                if compare(comp, rv, v)
                    @inbounds valtree[i] = rv
                    i = rc
                else
                    swapped = false
                end
            else
                if compare(comp, lv, v)
                    @inbounds valtree[i] = lv
                    i = lc
                else
                    swapped = false
                end
            end
        else        # contains only left child
            @inbounds lv = valtree[lc]
            if compare(comp, lv, v)
                @inbounds valtree[i] = lv
                i = lc
            else
                swapped = false
            end
        end
    end

    valtree[i] = v
end


function _binary_heap_pop!(comp::Comp, valtree::Array{T}) where {Comp,T}
    # extract root
    v = valtree[1]

    if length(valtree) == 1
        empty!(valtree)
    else
        valtree[1] = pop!(valtree)
        if length(valtree) > 1
            _heap_bubble_down!(comp, valtree, 1)
        end
    end
    v
end


function _make_binary_heap(comp::Comp, ty::Type{T}, xs) where {Comp,T}
    n = length(xs)
    valtree = copy(xs)
    for i = 2 : n
        _heap_bubble_up!(comp, valtree, i)
    end
    valtree
end


#################################################
#
#   heap type and constructors
#
#################################################

mutable struct BinaryHeap{T,Comp} <: AbstractHeap{T}
    comparer::Comp
    valtree::Vector{T}

    BinaryHeap{T,Comp}() where {T,Comp} = new{T,Comp}(Comp(), Vector{T}())

    function BinaryHeap{T,Comp}(xs::AbstractVector{T}) where {T,Comp}
        valtree = _make_binary_heap(Comp(), T, xs)
        new{T,Comp}(Comp(), valtree)
    end
end

const BinaryMinHeap{T} = BinaryHeap{T, LessThan}
const BinaryMaxHeap{T} = BinaryHeap{T, GreaterThan}

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
    _heap_bubble_up!(h.comparer, valtree, length(valtree))
    h
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

pop!(h::BinaryHeap{T}) where {T} = _binary_heap_pop!(h.comparer, h.valtree)
