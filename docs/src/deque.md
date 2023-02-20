# Deque

A Deque (short for Double-ended Queue) is an abstract data type that generalizes
a Queue for which elements can be added to or removed from both the front (head)
and the back (tail) in $O(1)$ time complexity.

The type `Deque` implements the Double-ended Queue as a list of fixed-size blocks
using an [unrolled linked list](https://en.wikipedia.org/wiki/Unrolled_linked_list).

!!! note
    Julia's `Vector` type also provides this interface, and thus can
    be used as a deque. However, the `Deque` type in DataStructures.jl is
    implemented as a list of contiguous blocks (default size = 1 kilo-byte). As a
    Deque grows, new blocks are created and linked to existing blocks.
    This approach prevents copying operations that take place when growing a `Vector`.

Benchmark shows that the performance of `Deque` is comparable to
`Vector` on `push!`, but is noticeably faster on `pushfirst!` (by about
30% to 40%).


## Constructors

```@autodocs
Modules = [DataStructures]
Pages = ["src/deque.jl"]
Order = [:type] # only types
```

## Usage

The `Deque` implements the following methods:

- [`==(x::Deque, y::Deque)`](@ref)
- [`empty!(d::Deque{T}) where T`](@ref)
- [`first(d::Deque)`](@ref)
- [`isempty(d::Deque)`](@ref)
- [`last(d::Deque)`](@ref)
- [`length(d::Deque)`](@ref)
- [`pop!(d::Deque{T}) where T`](@ref)
- [`popfirst!(d::Deque{T}) where T`](@ref)
- [`push!(d::Deque{T}, x) where T`](@ref)
- [`pushfirst!(d::Deque{T}, x) where T`](@ref)

-------

```@autodocs
Modules = [DataStructures]
Pages = ["src/deque.jl"]
Order = [:function] # only functions
```
