```@meta
DocTestSetup = :(using DataStructures)
```
# Priority Queue

The `PriorityQueue` type provides a basic priority queue implementation
allowing for arbitrary key and priority types. Multiple identical keys
are not permitted, but the priority of existing keys can be changed
efficiently.

## Constructors

```@autodocs
Modules = [DataStructures]
Pages = ["src/priorityqueue.jl"]
Order = [:type]
```

## Usage

The `PriorityQueue` type implements the following methods:

- [`delete!(pd::PriorityQueue, key)`](@ref)
- [`empty!(pd::PriorityQueue)`](@ref)
- [`first(pd::PriorityQueue)`](@ref)
- [`haskey(pd::PriorityQueue, key)`](@ref)
- [`isempty(pd::PriorityQueue)`](@ref)
- [`length(pd::PriorityQueue)`](@ref)
- [`popfirst!(pd::PriorityQueue)`](@ref)
- [`push!(pd::PriorityQueue)`](@ref)

!!! note
    `PriorityQueue` also behaves similarly to a `Dict` in that keys can be
    inserted and priorities accessed or changed using indexing notation.

    Examples:

    ```jldoctest
    julia> pq = PriorityQueue();

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

    It is also possible to iterate over the priorities and elements of the queue in sorted order.

    ```jldoctest
    julia> pq = PriorityQueue("a" => 2, "b" => 1, "c" => 3)
    PriorityQueue{String, Int64, Base.Order.ForwardOrdering} with 3 entries:
      "b" => 1
      "a" => 2
      "c" => 3

    julia> for priority in values(pq)
               println(priority)
           end
    1
    2
    3

    julia> for element in keys(pq)
               println(element)
           end
    b
    a
    c

    julia> for (element, priority) in pq
               println("$element $priority")
           end
    b 1
    a 2
    c 3
    ```

------

```@autodocs
Modules = [DataStructures]
Pages = ["src/priorityqueue.jl"]
Order = [:function]
```

```@meta
DocTestSetup = nothing
```
