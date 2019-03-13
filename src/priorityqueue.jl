# This file contains code that was formerly a part of Julia. License is MIT: http://julialang.org/license

# PriorityQueue
# -------------

"""
    PriorityQueue{K, V}([ord])

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
abstract type AbstractPriorityQueue{K,V,O<:Ordering} <: AbstractDict{K,V} end

struct PriorityQueue{K,V,O<:Ordering} <: AbstractPriorityQueue{K,V,O}
    xs::Array{Pair{K,V}, 1}
    o::O 
    index::Dict{K, Int}

    function PriorityQueue{K,V,O}(o::O) where {K,V,O<:Ordering}
        new{K,V,O}(Vector{Pair{K,V}}(), o, Dict{K, Int}())
    end

    function PriorityQueue{K,V,O}(o::O, itr) where {K,V,O<:Ordering}
        xs = Vector{Pair{K,V}}(undef, length(itr))
        index = Dict{K, Int}()
        for (i, (k, v)) in enumerate(itr)
            xs[i] = Pair{K,V}(k, v)
            if haskey(index, k)
                throw(ArgumentError("PriorityQueue keys must be unique"))
            end
            index[k] = i
        end
        pq = new{K,V,O}(xs, o, index)

        # heapify
        for i in heapparent(length(get_xs(pq))):-1:1
            percolate_down!(pq, i)
        end

        pq
    end
end

"""
    IntPriorityQueue{K, V}([ord])

PriorityQueue that accepts integer in 1:n as keys.
"""
struct IntPriorityQueue{K<:Integer,V,O<:Ordering} <: AbstractPriorityQueue{K,V,O}
    xs::Array{Pair{K,V}, 1}
    o::O 
    index::Vector{Int}
    n::Int

    function IntPriorityQueue{K,V,O}(o::O, n::Int) where {K<:Integer,V,O<:Ordering}
        if n < 0
            throw(ArgumentError("n cannot be negative"))
        end
        new{K,V,O}(Vector{Pair{K,V}}(), o, zeros(Int, n), n)
    end

    function IntPriorityQueue{K,V,O}(o::O, itr, n::Int) where {K<:Integer,V,O<:Ordering}
        xs = Vector{Pair{K,V}}(undef, length(itr))
        if n < 0
            throw(ArgumentError("n cannot be negative"))
        end
        index = zeros(Int, n)

        for (i, (k, v)) in enumerate(itr)
            xs[i] = Pair{K,V}(k, v)
            if k > n || k <= 0
                throw(ArgumentError("PriorityQueue keys must be in 1:n"))
            elseif index[k] != 0
                throw(ArgumentError("PriorityQueue keys must be unique"))
            end
            index[k] = i
        end
        pq = new{K,V,O}(xs, o, index, n)

        # heapify
        for i in heapparent(length(get_xs(pq))):-1:1
            percolate_down!(pq, i)
        end

        pq
    end
end

# Interface
get_index(pq::AbstractPriorityQueue) = nothing
get_index(pq::PriorityQueue) = pq.index
get_index(pq::IntPriorityQueue) = pq.index

get_xs(pq::AbstractPriorityQueue) = nothing
get_xs(pq::PriorityQueue) = pq.xs
get_xs(pq::IntPriorityQueue) = pq.xs

get_o(pq::AbstractPriorityQueue) = nothing
get_o(pq::PriorityQueue) = pq.o
get_o(pq::IntPriorityQueue) = pq.o

"""
    peek(pq)

Return the lowest priority key from a priority queue without removing that
key from the queue.
"""
peek(pq::AbstractPriorityQueue) = get_xs(pq)[1]

length(pq::AbstractPriorityQueue) = length(get_xs(pq))
isempty(pq::AbstractPriorityQueue) = isempty(get_xs(pq))

# Overwritten functions
haskey(pq::AbstractPriorityQueue, key) = false
haskey(pq::PriorityQueue, key) = haskey(pq.index, key)
haskey(pq::IntPriorityQueue, key) = (key <= pq.n && key > 0 && pq.index[key] != 0)

clear_index!(pq::AbstractPriorityQueue, key) = true
clear_index!(pq::PriorityQueue, key) = delete!(pq.index, key)
clear_index!(pq::IntPriorityQueue, key) = (pq.index[key] = 0)



function set_xs!(pq::AbstractPriorityQueue, i, data)
    get_index(pq)[data.first] = i
    get_xs(pq)[i] = data
end

# Any-Any constructors
PriorityQueue(o::Ordering=Forward) = PriorityQueue{Any,Any,typeof(o)}(o)
IntPriorityQueue(n::Int, o::Ordering=Forward) = IntPriorityQueue{Integer,Any,typeof(o)}(o, n)

# Construction from Pairs
PriorityQueue(ps::Pair...) = PriorityQueue(Forward, ps)
IntPriorityQueue(n::Int, ps::Pair...) = IntPriorityQueue(Forward, ps, n)

PriorityQueue(o::Ordering, ps::Pair...) = PriorityQueue(o, ps)
IntPriorityQueue(o::Ordering, n::Int, ps::Pair...) = IntPriorityQueue(o, ps, n)

PriorityQueue{K,V}(ps::Pair...) where {K,V} = PriorityQueue{K,V,ForwardOrdering}(Forward, ps)
IntPriorityQueue{K,V}(n::Int, ps::Pair...) where {K<:Integer,V} = IntPriorityQueue{K,V,ForwardOrdering}(Forward, ps, n)

PriorityQueue{K,V}(o::Ord, ps::Pair...) where {K,V,Ord<:Ordering} = PriorityQueue{K,V,Ord}(o, ps)
IntPriorityQueue{K,V}(o::Ord, n::Int, ps::Pair...) where {K<:Integer,V,Ord<:Ordering} = IntPriorityQueue{K,V,Ord}(o, ps, n)

# Construction specifying Key/Value types
# e.g., PriorityQueue{Int,Float64}([1=>1, 2=>2.0])
PriorityQueue{K,V}(kv) where {K,V} = PriorityQueue{K,V}(Forward, kv)
IntPriorityQueue{K,V}(kv, n::Int) where {K<:Integer,V} = IntPriorityQueue{K,V}(Forward, kv, n)

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
function IntPriorityQueue{K,V}(o::Ord, kv, n::Int) where {K<:Integer,V,Ord<:Ordering}
    try
        IntPriorityQueue{K,V,Ord}(o, kv, n)
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

PriorityQueue(o1::Ordering, o2::Ordering) = throw(ArgumentError("PriorityQueue with two parameters must be called with an Ordering and an interable of pairs"))
IntPriorityQueue(o1::Ordering, o2::Ordering) = throw(ArgumentError("PriorityQueue with two parameters must be called with an Ordering and an interable of pairs"))

PriorityQueue(kv, o::Ordering=Forward) = PriorityQueue(o, kv)
IntPriorityQueue(kv, n::Int, o::Ordering=Forward) = IntPriorityQueue(o, kv, n)

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
function IntPriorityQueue(o::Ordering, kv, n::Int)
    try
        _int_priority_queue_with_eltype(o, kv, n, eltype(kv))
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

_int_priority_queue_with_eltype(o::Ord, ps, n::Int, ::Type{Pair{K,V}} ) where {K,V,Ord} = IntPriorityQueue{  K,  V,Ord}(o, ps, n)
_int_priority_queue_with_eltype(o::Ord, kv, n::Int, ::Type{Tuple{K,V}}) where {K,V,Ord} = IntPriorityQueue{  K,  V,Ord}(o, kv, n)
_int_priority_queue_with_eltype(o::Ord, ps, n::Int, ::Type{Pair{K}}   ) where {K,  Ord} = IntPriorityQueue{  K,Any,Ord}(o, ps, n)
_int_priority_queue_with_eltype(o::Ord, kv, n::Int, ::Type            ) where {    Ord} = IntPriorityQueue{Any,Any,Ord}(o, kv, n)

## TODO: It seems impossible (or at least very challenging) to create the eltype below.
##       If deemed possible, please create a test and uncomment this definition.
# _priority_queue_with_eltype{  D,Ord}(o::Ord, ps, ::Type{Pair{K,V} where K}) = PriorityQueue{Any,  D,Ord}(o, ps)



function percolate_down!(pq::AbstractPriorityQueue, i::Integer)
    x = get_xs(pq)[i]
    @inbounds while (l = heapleft(i)) <= length(pq)
        r = heapright(i)
        j = r > length(pq) || lt(get_o(pq), get_xs(pq)[l].second, get_xs(pq)[r].second) ? l : r
        if lt(get_o(pq), get_xs(pq)[j].second, x.second)
            set_xs!(pq, i, get_xs(pq)[j])
            i = j
        else
            break
        end
    end
    set_xs!(pq, i, x)
end


function percolate_up!(pq::AbstractPriorityQueue, i::Integer)
    x = get_xs(pq)[i]
    @inbounds while i > 1
        j = heapparent(i)
        if lt(get_o(pq), x.second, get_xs(pq)[j].second)
            set_xs!(pq, i, get_xs(pq)[j])
            i = j
        else
            break
        end
    end
    set_xs!(pq, i, x)
end

# Equivalent to percolate_up! with an element having lower priority than any other
function force_up!(pq::AbstractPriorityQueue, i::Integer)
    x = get_xs(pq)[i]
    @inbounds while i > 1
        j = heapparent(i)
        set_xs!(pq, i, get_xs(pq)[j])
        i = j
    end
    set_xs!(pq, i, x)
end

function getindex(pq::AbstractPriorityQueue{K,V}, key) where {K,V}
    get_xs(pq)[get_index(pq)[key]].second
end

# Uses only one Dict getindex
function get(pq::PriorityQueue{K,V}, key, deflt) where {K,V}
    i = get(pq.index, key, 0)
    i == 0 ? deflt : pq.xs[i].second
end

function get(pq::IntPriorityQueue{K,V}, key, deflt) where {K<:Integer,V}
    haskey(pq, key) ? get_xs(pq)[get_index(pq)[key]].second : deflt
end

# Change the priority of an existing element, or equeue it if it isn't present.
function setindex!(pq::AbstractPriorityQueue{K, V}, value, key) where {K,V}
    if haskey(pq, key)
        i = get_index(pq)[key]
        oldvalue = get_xs(pq)[i].second
        get_xs(pq)[i] = Pair{K,V}(key, value)
        if lt(get_o(pq), oldvalue, value)
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
    enqueue!(pq, k=>v)

Insert the a key `k` into a priority queue `pq` with priority `v`.

```jldoctest
julia> a = PriorityQueue(PriorityQueue("a"=>1, "b"=>2, "c"=>3))
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 3 entries:
  "c" => 3
  "b" => 2
  "a" => 1

julia> enqueue!(a, "d"=>4)
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 4 entries:
  "c" => 3
  "b" => 2
  "a" => 1
  "d" => 4
```
"""
function enqueue!(pq::AbstractPriorityQueue{K,V}, pair::Pair{K,V}) where {K,V}
    key = pair.first
    if haskey(pq, key)
        throw(ArgumentError("PriorityQueue keys must be unique"))
    end
    push!(get_xs(pq), pair)
    set_xs!(pq, length(get_xs(pq)), pair)
    percolate_up!(pq, length(pq))

    return pq
end

"""
enqueue!(pq, k, v)

Insert the a key `k` into a priority queue `pq` with priority `v`.

"""
enqueue!(pq::AbstractPriorityQueue, key, value) = enqueue!(pq, key=>value)
enqueue!(pq::AbstractPriorityQueue{K,V}, kv) where {K,V} = enqueue!(pq, Pair{K,V}(kv.first, kv.second))

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
function dequeue!(pq::AbstractPriorityQueue)
    x = get_xs(pq)[1]
    y = pop!(get_xs(pq))
    if !isempty(pq)
        set_xs!(pq, 1, y)
        percolate_down!(pq, 1)
    end
    clear_index!(pq, x.first) #delete!(pq.index, x.first)
    x.first
end

function dequeue!(pq::AbstractPriorityQueue, key)
    idx = get_index(pq)[key]
    force_up!(pq, idx)
    dequeue!(pq)
    key
end

"""
    dequeue_pair!(pq)

Remove and return a the lowest priority key and value from a priority queue as a pair.

```jldoctest
julia> a = PriorityQueue(["a","b","c"],[2,3,1],Base.Order.Forward)
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "b" => 3
  "a" => 2

julia> dequeue_pair!(a)
"c" => 1

julia> a
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 2 entries:
  "b" => 3
  "a" => 2
```
"""
function dequeue_pair!(pq::AbstractPriorityQueue)
    x = get_xs(pq)[1]
    y = pop!(get_xs(pq))
    if !isempty(pq)
        set_xs!(pq, 1, y)
        percolate_down!(pq, 1)
    end
    clear_index!(pq, x.first)
    x
end

function dequeue_pair!(pq::AbstractPriorityQueue, key)
    idx = get_index(pq)[key]
    force_up!(pq, idx)
    dequeue_pair!(pq)
end

"""
    delete!(pq, key)
Delete the mapping for the given key in a priority queue, and return the priority queue.
# Examples
```jldoctest
julia> q = PriorityQueue(Base.Order.Forward, "a"=>2, "b"=>3, "c"=>1)
PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 3 entries:
  "c" => 1
  "b" => 3
  "a" => 2
julia> delete!(q, "b")
DataStructures.PriorityQueue{String,Int64,Base.Order.ForwardOrdering} with 2 entries:
  "c" => 1
  "a" => 2
```
"""
function delete!(pq::AbstractPriorityQueue, key)
    dequeue_pair!(pq, key)
    pq
end

function empty!(pq::AbstractPriorityQueue)
    empty!(get_xs(pq))
    empty!(get_index(pq))
    pq
end

# Unordered iteration through key value pairs in a PriorityQueue
function _iterate(pq::AbstractPriorityQueue, state)
    state == nothing && return nothing
    (k, idx), i = state
    return (get_xs(pq)[idx], i)
end

iterate(pq::PriorityQueue) = _iterate(pq, iterate(get_index(pq)))
iterate(pq::PriorityQueue, i) = _iterate(pq, iterate(get_index(pq), i))

array_to_dict(A::Vector{Int}) = Dict(Pair(i, x) for (i, x) in enumerate(A) if x != 0)

iterate(pq::IntPriorityQueue) = _iterate(pq, iterate(array_to_dict(pq.index)))
iterate(pq::IntPriorityQueue, i) = _iterate(pq, iterate(array_to_dict(pq.index), i))
