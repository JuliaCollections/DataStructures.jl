# Binary heap (non-mutable)

#################################################
#
#   core implementation
#
#################################################

function _heap_bubble_up!{Comp,T}(comp::Comp, valtree::Array{T}, i::Int)
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

function _heap_bubble_down!{Comp,T}(comp::Comp, valtree::Array{T}, i::Int)
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


function _binary_heap_pop!{Comp,T}(comp::Comp, valtree::Array{T})
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


function _make_binary_heap{Comp,T}(comp::Comp, ty::Type{T}, xs)
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

type BinaryHeap{T,Comp} <: AbstractHeap{T}
    comparer::Comp
    valtree::Array{T}

    function BinaryHeap(comp::Comp)
        new(comp, Array(T,0))
    end

    function BinaryHeap(comp::Comp, xs)  # xs is an iterable collection of values
        valtree = _make_binary_heap(comp, T, xs)
        new(comp, valtree)
    end
end

function binary_minheap{T}(ty::Type{T})
    BinaryHeap{T,LessThan}(LessThan())
end

binary_maxheap{T}(ty::Type{T}) = BinaryHeap{T,GreaterThan}(GreaterThan())
binary_minheap{T}(xs::AbstractVector{T}) = BinaryHeap{T,LessThan}(LessThan(), xs)
binary_maxheap{T}(xs::AbstractVector{T}) = BinaryHeap{T,GreaterThan}(GreaterThan(), xs)

#################################################
#
#   interfaces
#
#################################################

length(h::BinaryHeap) = length(h.valtree)

isempty(h::BinaryHeap) = isempty(h.valtree)

function push!{T}(h::BinaryHeap{T}, v::T)
    valtree = h.valtree
    push!(valtree, v)
    _heap_bubble_up!(h.comparer, valtree, length(valtree))
end


"""
    top(h::BinaryHeap)

Returns the element at the top of the heap `h`.
"""
top(h::BinaryHeap) = h.valtree[1]

pop!{T}(h::BinaryHeap{T}) = _binary_heap_pop!(h.comparer, h.valtree)
