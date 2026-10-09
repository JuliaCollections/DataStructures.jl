```@meta
DocTestSetup = :(using DataStructures)
```

# Queue

The Queue data structure, also known as *First In, First Out* (FIFO) queue, allows
addition and deletion of items in opposite ends of the data structure. Insertion is
performed in the back of the queue while deletion is performed in the front of the
queue. In DataStructures.jl, the `Queue` type is a light-weight wrapper around the
[Deque](./deque.md) type.

Queues are often used as a base for many different data structures, some of its
variations implemented by DataStructures.jl include:

- [Double Ended Queues](./deque.md)
- [Circular Double Ended Queues](./circ_deque.md)
- [Priority Queues](./priority-queue.md)

## Constructors

```@autodocs
Modules = [DataStructures]
Pages = ["src/queue.jl"]
Order = [:type]
```

## Usage

The `Queue` type implements the following methods:

- [`eltype(::Type{Queue{T}}) where {T}`](@ref)
- [`first(q::Queue)`](@ref)
- [`isempty(q::Queue)`](@ref)
- [`length(q::Queue)`](@ref)
- [`last(q::Queue)`](@ref)
- [`push!(q::Queue, x)`](@ref)
- [`popfirst!(q::Queue)`](@ref)

-----------

```@autodocs
Modules = [DataStructures]
Pages = ["src/queue.jl"]
Order = [:function]
```

```@meta
DocTestSetup = nothing
```
