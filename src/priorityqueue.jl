# This file contains code that was formerly a part of Julia. License is MIT: http://julialang.org/license

# PriorityQueue
# -------------

"""
    PriorityQueue(K, V, [ord])

Construct a new [`PriorityQueue`](@ref), with keys of type
`K` and values/priorites of type `V`.
If an order is not given, the priority queue is min-ordered using
the default comparison for `V`.

A `PriorityQueue` acts like a `Dict`, mapping values to their
priorities, with the addition of a `dequeue!` function to remove the
lowest priority element.

```jldoctest
julia> a = PriorityQueue(["a","b","c"],[2,3,1],Base.Order.Forward)
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "b" => 3
  "a" => 2
```
"""
type PriorityQueue{K,V,O<:Ordering} <: Associative{K,V}
    # Binary heap of (element, priority) pairs.
    xs::Array{Pair{K,V}, 1}
    o::O

    # Map elements to their index in xs
    index::Dict{K, Int}

    function PriorityQueue(o::O)
        new(Vector{Pair{K,V}}(0), o, Dict{K, Int}())
    end

    PriorityQueue() = PriorityQueue{K,V,O}(Forward)

    function PriorityQueue(ks::AbstractArray{K}, vs::AbstractArray{V},
                           o::O)
        # TODO: maybe deprecate
        if length(ks) != length(vs)
            throw(ArgumentError("key and value arrays must have equal lengths"))
        end
        PriorityQueue{K,V,O}(zip(ks, vs), o)
    end

    function PriorityQueue(itr, o::O)
        xs = Vector{Pair{K,V}}(length(itr))
        index = Dict{K, Int}()
        for (i, (k, v)) in enumerate(itr)
            xs[i] = Pair{K,V}(k, v)
            if haskey(index, k)
                throw(ArgumentError("PriorityQueue keys must be unique"))
            end
            index[k] = i
        end
        pq = new(xs, o, index)

        # heapify
        for i in heapparent(length(pq.xs)):-1:1
            percolate_down!(pq, i)
        end

        pq
    end
end

PriorityQueue(o::Ordering=Forward) = PriorityQueue{Any,Any,typeof(o)}(o)
PriorityQueue{K,V}(::Type{K}, ::Type{V}, o::Ordering=Forward) = PriorityQueue{K,V,typeof(o)}(o)

# TODO: maybe deprecate
PriorityQueue{K,V}(ks::AbstractArray{K}, vs::AbstractArray{V},
                   o::Ordering=Forward) = PriorityQueue{K,V,typeof(o)}(ks, vs, o)

PriorityQueue{K,V}(kvs::Associative{K,V}, o::Ordering=Forward) = PriorityQueue{K,V,typeof(o)}(kvs, o)

PriorityQueue{K,V}(a::AbstractArray{Tuple{K,V}}, o::Ordering=Forward) = PriorityQueue{K,V,typeof(o)}(a, o)

length(pq::PriorityQueue) = length(pq.xs)
isempty(pq::PriorityQueue) = isempty(pq.xs)
haskey(pq::PriorityQueue, key) = haskey(pq.index, key)

"""
    peek(pq)

Return the lowest priority key from a priority queue without removing that
key from the queue.
"""
peek(pq::PriorityQueue) = pq.xs[1]

function percolate_down!(pq::PriorityQueue, i::Integer)
    x = pq.xs[i]
    @inbounds while (l = heapleft(i)) <= length(pq)
        r = heapright(i)
        j = r > length(pq) || lt(pq.o, pq.xs[l].second, pq.xs[r].second) ? l : r
        if lt(pq.o, pq.xs[j].second, x.second)
            pq.index[pq.xs[j].first] = i
            pq.xs[i] = pq.xs[j]
            i = j
        else
            break
        end
    end
    pq.index[x.first] = i
    pq.xs[i] = x
end


function percolate_up!(pq::PriorityQueue, i::Integer)
    x = pq.xs[i]
    @inbounds while i > 1
        j = heapparent(i)
        if lt(pq.o, x.second, pq.xs[j].second)
            pq.index[pq.xs[j].first] = i
            pq.xs[i] = pq.xs[j]
            i = j
        else
            break
        end
    end
    pq.index[x.first] = i
    pq.xs[i] = x
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

function getindex{K,V}(pq::PriorityQueue{K,V}, key)
    pq.xs[pq.index[key]].second
end


function get{K,V}(pq::PriorityQueue{K,V}, key, deflt)
    i = get(pq.index, key, 0)
    i == 0 ? deflt : pq.xs[i].second
end


# Change the priority of an existing element, or equeue it if it isn't present.
function setindex!{K,V}(pq::PriorityQueue{K, V}, value, key)
    if haskey(pq, key)
        i = pq.index[key]
        oldvalue = pq.xs[i].second
        pq.xs[i] = Pair{K,V}(key, value)
        if lt(pq.o, oldvalue, value)
            percolate_down!(pq, i)
        else
            percolate_up!(pq, i)
        end
    else
        enqueue!(pq, key, value)
    end
    value
end

"""
    enqueue!(pq, k, v)

Insert the a key `k` into a priority queue `pq` with priority `v`.

```jldoctest
julia> a = PriorityQueue(["a","b","c"],[2,3,1],Base.Order.Forward)
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "b" => 3
  "a" => 2

julia> enqueue!(a, "d", 4)
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 4 entries:
  "c" => 1
  "b" => 3
  "a" => 2
  "d" => 4
```
"""
function enqueue!{K,V}(pq::PriorityQueue{K,V}, key, value)
    if haskey(pq, key)
        throw(ArgumentError("PriorityQueue keys must be unique"))
    end
    push!(pq.xs, Pair{K,V}(key, value))
    pq.index[key] = length(pq)
    percolate_up!(pq, length(pq))
    pq
end

"""
    dequeue!(pq)

Remove and return the lowest priority key from a priority queue.

```jldoctest
julia> a = PriorityQueue(["a","b","c"],[2,3,1],Base.Order.Forward)
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "b" => 3
  "a" => 2

julia> dequeue!(a)
"c"

julia> a
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 2 entries:
  "b" => 3
  "a" => 2
```
"""
function dequeue!(pq::PriorityQueue)
    x = pq.xs[1]
    y = pop!(pq.xs)
    if !isempty(pq)
        pq.xs[1] = y
        pq.index[y.first] = 1
        percolate_down!(pq, 1)
    end
    delete!(pq.index, x.first)
    x.first
end

function dequeue!(pq::PriorityQueue, key)
    idx = pq.index[key]
    force_up!(pq, idx)
    dequeue!(pq)
    key
end

# Unordered iteration through key value pairs in a PriorityQueue
start(pq::PriorityQueue) = start(pq.index)

done(pq::PriorityQueue, i) = done(pq.index, i)

function next{K,V}(pq::PriorityQueue{K,V}, i)
    (k, idx), i = next(pq.index, i)
    return (pq.xs[idx], i)
end
