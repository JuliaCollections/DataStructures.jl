```@meta
DocTestSetup = :(using DataStructures)
```

# Priority Queue

The `PriorityQueue` type provides a basic priority queue implementation
allowing for arbitrary key and priority types. Multiple identical keys
are not permitted, but the priority of existing keys can be changed
efficiently.

Usage:

```julia
PriorityQueue{K, V}()     # construct a new priority queue with keys of type K and priorities of type V (forward ordering by default)
PriorityQueue{K, V}(ord)  # construct a new priority queue with the given types and ordering ord (Base.Order.Forward or Base.Order.Reverse)
enqueue!(pq, k, v)        # insert the key k into pq with priority v
enqueue!(pq, k=>v)        # (same, using Pairs)
dequeue!(pq)              # remove and return the lowest priority key
dequeue_pair!(pq)         # remove and return the lowest priorty key and value
peek(pq)                  # return the lowest priority key and value without removing it
delete!(pq, k)            # delete the mapping for the given key in a priority queue, and return the priority queue.
```

`PriorityQueue` also behaves similarly to a `Dict` in that keys can be
inserted and priorities accessed or changed using indexing notation.

Examples:

```jldoctest
julia> # Julia code
       pq = PriorityQueue();

julia> # Insert keys with associated priorities
       pq["a"] = 10; pq["b"] = 5; pq["c"] = 15; pq
PriorityQueue{Any, Any, Base.Order.ForwardOrdering} with 3 entries:
  "b" => 5
  "a" => 10
  "c" => 15

julia> # Change the priority of an existing key
       pq["a"] = 0; pq
PriorityQueue{Any, Any, Base.Order.ForwardOrdering} with 3 entries:
  "a" => 0
  "b" => 5
  "c" => 15
```

```@meta
DocTestSetup = nothing
```
