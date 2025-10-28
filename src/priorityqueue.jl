# This file contains code that was formerly a part of Julia. License is MIT: http://julialang.org/license

# PriorityQueue
# -------------

"""
    PriorityQueue{K, V}([ord])

Construct a new `PriorityQueue`, with keys of type `K` and values/priorities
of type `V`. If an order is not given, the priority queue is min-ordered using
the default comparison for `V`.

A `PriorityQueue` acts like a `Dict`, mapping values to their
priorities. New elements are added using `push!` and retrieved
using `popfirst!` or `popat!` based on their priority.

Parameters
---------

`K::Type` Data type for the keys

`V::Type` Data type for the values/priorities

`ord::Base.Ordering` Priority queue ordering

# Examples
```jldoctest
julia> PriorityQueue(Base.Order.Forward, "a" => 2, "b" => 3, "c" => 1)
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "a" => 2
  "b" => 3
```
"""
struct PriorityQueue{K,V,O<:Ordering} <: AbstractDict{K,V}
    # Binary heap of (element, priority) pairs.
    xs::Vector{Pair{K,V}}
    o::O

    # Map elements to their index in xs
    index::Dict{K, Int}

    function PriorityQueue{K,V,O}(o::O) where {K,V,O<:Ordering}
        new{K,V,O}(Vector{Pair{K,V}}(), o, Dict{K, Int}())
    end

    PriorityQueue{K, V, O}(xs::Vector{Pair{K,V}}, o::O, index::Dict{K, Int}) where {K,V,O<:Ordering} = new(xs, o, index)

    function PriorityQueue{K,V,O}(o::O, itr) where {K,V,O<:Ordering}
        xs = Vector{Pair{K,V}}(undef, length(itr))
        index = Dict{K, Int}()
        @inbounds for (i, (k, v)) in enumerate(itr)
            xs[i] = Pair{K,V}(k, v)
            if haskey(index, k)
                throw(ArgumentError("PriorityQueue keys must be unique"))
            end
            index[k] = i
        end
        pq = new{K,V,O}(xs, o, index)

        # heapify
        for i in heapparent(length(pq.xs)):-1:1
            @inbounds percolate_down!(pq, i)
        end

        return pq
    end
end

# A copy constructor
PriorityQueue(xs::Vector{Pair{K,V}}, o::O, index::Dict{K, Int}) where {K,V,O<:Ordering} =
    PriorityQueue{K,V,O}(xs, o, index)

# Any-Any constructors
PriorityQueue(o::Ordering=Forward) = PriorityQueue{Any,Any,typeof(o)}(o)

# Construction from Pairs
PriorityQueue(ps::Pair...) = PriorityQueue(Forward, ps)
PriorityQueue(o::Ordering, ps::Pair...) = PriorityQueue(o, ps)
PriorityQueue{K,V}(ps::Pair...) where {K,V} = PriorityQueue{K,V,ForwardOrdering}(Forward, ps)
PriorityQueue{K,V}(o::Ord, ps::Pair...) where {K,V,Ord<:Ordering} = PriorityQueue{K,V,Ord}(o, ps)

# Construction specifying Key/Value types
# e.g., PriorityQueue{Int,Float64}([1=>1, 2=>2.0])
PriorityQueue{K,V}(kv) where {K,V} = PriorityQueue{K,V}(Forward, kv)
function PriorityQueue{K,V}(o::Ord, kv) where {K,V,Ord<:Ordering}
    try
        PriorityQueue{K,V,Ord}(o, kv)
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("PriorityQueue(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

# Construction inferring Key/Value types from input
# e.g. PriorityQueue{}

PriorityQueue(o1::Ordering, o2::Ordering) = throw(ArgumentError("PriorityQueue with two parameters must be called with an Ordering and an iterable of pairs"))
PriorityQueue(kv, o::Ordering=Forward) = PriorityQueue(o, kv)
function PriorityQueue(o::Ordering, kv)
    try
        _priority_queue_with_eltype(o, kv, eltype(kv))
    catch e
        if not_iterator_of_pairs(kv)
            throw(ArgumentError("PriorityQueue(kv): kv needs to be an iterator of tuples or pairs"))
        else
            rethrow(e)
        end
    end
end

_priority_queue_with_eltype(o::Ord, ps, ::Type{Pair{K,V}} ) where {K,V,Ord} = PriorityQueue{  K,  V,Ord}(o, ps)
_priority_queue_with_eltype(o::Ord, kv, ::Type{Tuple{K,V}}) where {K,V,Ord} = PriorityQueue{  K,  V,Ord}(o, kv)
_priority_queue_with_eltype(o::Ord, ps, ::Type{Pair{K}}   ) where {K,  Ord} = PriorityQueue{  K,Any,Ord}(o, ps)
_priority_queue_with_eltype(o::Ord, kv, ::Type            ) where {    Ord} = PriorityQueue{Any,Any,Ord}(o, kv)

## TODO: It seems impossible (or at least very challenging) to create the eltype below.
##       If deemed possible, please create a test and uncomment this definition.
# _priority_queue_with_eltype{  D,Ord}(o::Ord, ps, ::Type{Pair{K,V} where K}) = PriorityQueue{Any,  D,Ord}(o, ps)


"""
    length(pq::PriorityQueue)

Return the number of pairs (`k`, `v`) in the priority queue `pq`.
"""
Base.length(pq::PriorityQueue) = length(pq.xs)

"""
    isempty(pq::PriorityQueue)

Verify if priority queue `pq` is empty.
"""
Base.isempty(pq::PriorityQueue) = isempty(pq.xs)

"""
    haskey(pq::PriorityQueue, key)

Verify if priority queue `pq` has `key` in its keys.

# Example

```jldoctest
julia> pq = PriorityQueue("a" => 1, "b" => 2, "c" => 3)
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 3 entries:
  "a" => 1
  "b" => 2
  "c" => 3

julia> haskey(pq, "a")
true

julia> haskey(pq, "e")
false
```
"""
Base.haskey(pq::PriorityQueue, key) = haskey(pq.index, key)

"""
    first(pq::PriorityQueue)

Return the lowest priority pair (`k`, `v`) from `pq` without removing it from the
priority queue.
"""
Base.first(pq::PriorityQueue) = first(pq.xs)

Base.@propagate_inbounds function percolate_down!(pq::PriorityQueue, i::Integer)
    @boundscheck checkbounds(pq.xs, i)

    @inbounds x = pq.xs[i]
    @inbounds while (l = heapleft(i)) <= length(pq)
        r = heapright(i)
        j = r > length(pq) || lt(pq.o, pq.xs[l].second, pq.xs[r].second) ? l : r
        xj = pq.xs[j]
        if lt(pq.o, xj.second, x.second)
            pq.index[xj.first] = i
            pq.xs[i] = xj
            i = j
        else
            break
        end
    end
    pq.index[x.first] = i
    @inbounds pq.xs[i] = x
end


Base.@propagate_inbounds function percolate_up!(pq::PriorityQueue, i::Integer)
    @boundscheck checkbounds(pq.xs, i)

    @inbounds x = pq.xs[i]
    @inbounds while i > 1
        j = heapparent(i)
        xj = pq.xs[j]
        if lt(pq.o, x.second, xj.second)
            pq.index[xj.first] = i
            pq.xs[i] = xj
            i = j
        else
            break
        end
    end
    pq.index[x.first] = i
    @inbounds pq.xs[i] = x
end

# Equivalent to percolate_up! with an element having lower priority than any other
function force_up!(pq::PriorityQueue, i::Integer)
    x = pq.xs[i]
    @inbounds while i > 1
        j = heapparent(i)
        pq.index[pq.xs[j].first] = i
        pq.xs[i] = pq.xs[j]
        i = j
    end
    pq.index[x.first] = i
    pq.xs[i] = x
end

Base.getindex(pq::PriorityQueue, key) = pq.xs[pq.index[key]].second

function Base.get(pq::PriorityQueue, key, default)
    i = get(pq.index, key, 0)
    i == 0 ? default : pq.xs[i].second
end

function Base.get!(pq::PriorityQueue, key, default)
    i = get(pq.index, key, 0)
    if i == 0
        push!(pq, key=>default)
        return default
    else
        return pq.xs[i].second
    end
end

# Change the priority of an existing element, or enqueue it if it isn't present.
function Base.setindex!(pq::PriorityQueue{K, V}, value, key) where {K,V}
    i = get(pq.index, key, 0)
    @inbounds if i != 0
        oldvalue = pq.xs[i].second
        pq.xs[i] = Pair{K,V}(key, value)
        if lt(pq.o, oldvalue, value)
            percolate_down!(pq, i)
        else
            percolate_up!(pq, i)
        end
    else
        push!(pq, key=>value)
    end
    return value
end

"""
    push!(pq::PriorityQueue{K,V}, pair::Pair{K,V}) where {K,V}

Insert the a key `k` into a priority queue `pq` with priority `v`.

# Examples

```jldoctest
julia> a = PriorityQueue("a" => 1, "b" => 2, "c" => 3, "e" => 5)
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 4 entries:
  "a" => 1
  "b" => 2
  "c" => 3
  "e" => 5

julia> push!(a, "d" => 4)
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 5 entries:
  "a" => 1
  "b" => 2
  "c" => 3
  "d" => 4
  "e" => 5
```
"""
function Base.push!(pq::PriorityQueue{K,V}, pair::Pair{K,V}) where {K,V}
    key = pair.first
    if haskey(pq, key)
        throw(ArgumentError("PriorityQueue keys must be unique"))
    end
    push!(pq.xs, pair)
    pq.index[key] = length(pq)
    percolate_up!(pq, length(pq))

    return pq
end

Base.push!(pq::PriorityQueue{K,V}, kv::Pair) where {K,V} = push!(pq, Pair{K,V}(kv.first, kv.second))

"""
    popfirst!(pq::PriorityQueue)

Remove and return the lowest priority key and value from a priority queue `pq` as a pair.

# Examples

```jldoctest
julia> a = PriorityQueue(Base.Order.Forward, "a" => 2, "b" => 3, "c" => 1)
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "a" => 2
  "b" => 3

julia> popfirst!(a)
"c" => 1

julia> a
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 2 entries:
  "a" => 2
  "b" => 3
```
"""
function Base.popfirst!(pq::PriorityQueue)
    x = pq.xs[1]
    y = pop!(pq.xs)
    if !isempty(pq)
        @inbounds pq.xs[1] = y
        pq.index[y.first] = 1
        @inbounds percolate_down!(pq, 1)
    end
    delete!(pq.index, x.first)
    return x
end

function Base.popat!(pq::PriorityQueue, key)
    idx = pq.index[key]
    force_up!(pq, idx)
    popfirst!(pq)
end

"""
    delete!(pq::PriorityQueue, key)

Delete the mapping for the given `key` in a priority queue `pq` and return the priority queue.

# Examples

```jldoctest
julia> q = PriorityQueue(Base.Order.Forward, "a" => 2, "b" => 3, "c" => 1)
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "a" => 2
  "b" => 3
julia> delete!(q, "b")
PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 2 entries:
  "c" => 1
  "a" => 2
```
"""
function Base.delete!(pq::PriorityQueue, key)
    popat!(pq, key)
    return pq
end

"""
    empty!(pq::PriorityQueue)

Reset priority queue `pq`.
"""
function Base.empty!(pq::PriorityQueue)
    empty!(pq.xs)
    empty!(pq.index)
    return pq
end

Base.empty(pq::PriorityQueue) = PriorityQueue(empty(pq.xs), pq.o, empty(pq.index))

Base.merge!(d::SortedDict, other::PriorityQueue) = invoke(merge!, Tuple{AbstractDict, PriorityQueue}, d, other)

function Base.merge!(d::AbstractDict, other::PriorityQueue)
    next = iterate(other, false)
    while next !== nothing
        (k, v), state = next
        d[k] = v
        next = iterate(other, state)
    end
    return d
end

function Base.merge!(combine::Function, d::AbstractDict, other::PriorityQueue)
    next = iterate(other, false)
    while next !== nothing
        (k, v), state = next
        d[k] = haskey(d, k) ? combine(d[k], v) : v
        next = iterate(other, state)
    end
    return d
end

# Opaque not to be exported.
mutable struct _PQIteratorState{K, V, O <: Ordering}
    pq::PriorityQueue{K, V, O}
    _PQIteratorState{K, V, O}(pq::PriorityQueue{K, V, O}) where {K, V, O <: Ordering} = new(pq)
end

_PQIteratorState(pq::PriorityQueue{K, V, O}) where {K, V, O <: Ordering} = _PQIteratorState{K, V, O}(pq)

# Unordered iteration through key value pairs in a PriorityQueue
# O(n) iteration.
function _iterate(pq::PriorityQueue, state)
    (k, idx), i = state
    return (pq.xs[idx], i)
end
_iterate(pq::PriorityQueue, ::Nothing) = nothing

Base.iterate(pq::PriorityQueue, ::Nothing) = nothing

function Base.iterate(pq::PriorityQueue, ordered::Bool=true)
    if ordered
        isempty(pq) && return nothing
        state = _PQIteratorState(PriorityQueue(copy(pq.xs), pq.o, copy(pq.index)))
        return popfirst!(state.pq), state
    else
        _iterate(pq, iterate(pq.index))
    end
end

function Base.iterate(pq::PriorityQueue, state::_PQIteratorState)
    isempty(state.pq) && return nothing
    return popfirst!(state.pq), state
end

Base.iterate(pq::PriorityQueue, i) = _iterate(pq, iterate(pq.index, i))
