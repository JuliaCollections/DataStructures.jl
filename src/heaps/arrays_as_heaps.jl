# This contains code that was formerly a part of Julia. License is MIT: http://julialang.org/license

import Base.Order: Forward, Ordering, lt


# Heap operations on flat arrays
# ------------------------------


# Binary heap indexing
heapleft(i::Integer) = 2i
heapright(i::Integer) = 2i + 1
heapparent(i::Integer) = div(i, 2)


# Binary min-heap percolate down.
function percolate_down!(xs::AbstractArray, i::Integer, x=xs[i], o::Ordering=Forward, len::Integer=length(xs))
    @inbounds while (l = heapleft(i)) <= len
        r = heapright(i)
        j = r > len || lt(o, xs[l], xs[r]) ? l : r
        if lt(o, xs[j], x)
            xs[i] = xs[j]
            i = j
        else
            break
        end
    end
    xs[i] = x
end

percolate_down!(xs::AbstractArray, i::Integer, o::Ordering, len::Integer=length(xs)) = percolate_down!(xs, i, xs[i], o, len)


# Binary min-heap percolate up.
function percolate_up!(xs::AbstractArray, i::Integer, x=xs[i], o::Ordering=Forward)
    @inbounds while (j = heapparent(i)) >= 1
        if lt(o, x, xs[j])
            xs[i] = xs[j]
            i = j
        else
            break
        end
    end
    xs[i] = x
end

percolate_up!(xs::AbstractArray{T}, i::Integer, o::Ordering) where {T} = percolate_up!(xs, i, xs[i], o)

"""
    heappop!(v, [ord])

Given a binary heap-ordered array, remove and return the lowest ordered element.
For efficiency, this function does not check that the array is indeed heap-ordered.
"""
function heappop!(xs::AbstractArray, o::Ordering=Forward)
    x = xs[1]
    y = pop!(xs)
    if !isempty(xs)
        percolate_down!(xs, 1, y, o)
    end
    x
end

"""
    heappush!(v, x, [ord])

Given a binary heap-ordered array, push a new element `x`, preserving the heap property.
For efficiency, this function does not check that the array is indeed heap-ordered.
"""
function heappush!(xs::AbstractArray, x, o::Ordering=Forward)
    push!(xs, x)
    percolate_up!(xs, length(xs), x, o)
    xs
end


# Turn an arbitrary array into a binary min-heap in linear time.
"""
    heapify!(v, ord::Ordering=Forward)

In-place [`heapify`](@ref).
"""
function heapify!(xs::AbstractArray, o::Ordering=Forward)
    for i in heapparent(length(xs)):-1:1
        percolate_down!(xs, i, o)
    end
    xs
end

"""
    heapify(v, ord::Ordering=Forward)

Returns a new vector in binary heap order, optionally using the given ordering.
```jldoctest
julia> a = [1,3,4,5,2];

julia> heapify(a)
5-element Array{Int64,1}:
 1
 2
 4
 5
 3

julia> heapify(a, Base.Order.Reverse)
5-element Array{Int64,1}:
 5
 3
 4
 1
 2
```
"""
heapify(xs::AbstractArray, o::Ordering=Forward) = heapify!(copyto!(similar(xs), xs), o)

"""
    isheap(v, ord::Ordering=Forward)

Return `true` if an array is heap-ordered according to the given order.

```jldoctest
julia> a = [1,2,3]
3-element Array{Int64,1}:
 1
 2
 3

julia> isheap(a,Base.Order.Forward)
true

julia> isheap(a,Base.Order.Reverse)
false
```
"""
function isheap(xs::AbstractArray, o::Ordering=Forward)
    for i in 1:div(length(xs), 2)
        if lt(o, xs[heapleft(i)], xs[i]) ||
           (heapright(i) <= length(xs) && lt(o, xs[heapright(i)], xs[i]))
            return false
        end
    end
    true
end
