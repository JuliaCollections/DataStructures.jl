```@meta
DocTestSetup = :(using DataStructures)
```

# Stack

The Stack data structure corresponds to a *Last In, First Out* (LIFO) queue in 
which elements are added to and removed from only one of the ends of the queue.
In DataStructures.jl the [`Stack`](./stack.md) type is a light-weight wrapper around
the [`Deque`](./deque.md) type.

!!! note "Notes on the Iterator interface implemented by the Stack"
    The `Stack` type implements the Julia Iterator interface; iterating
    over `Stack` returns items in *First In, Last Out* (FILO) order, i.e. "from top
    to bottom" of the stack. There is also a `Iterators.reverse` function which
    iterates over the items in *First In, First Out* (FIFO) order, or "from bottom
    to top" of the stack.

    ```jldoctest
    julia> s = Stack{Int64}()
    Stack{Int64}(Deque [Int64[]])

    julia> for i in 1:4
               push!(s, i)
           end

    julia> for el in s # top to bottom iteration 
               println(el)
           end
    4
    3
    2
    1

    julia> for el in Iterators.reverse(s) # bottom to top iteration 
               println(el)
           end
    1
    2
    3
    4
    ```

## Constructors

```@autodocs
Modules = [DataStructures]
Pages = ["src/stack.jl"]
Order = [:type]
```

## Usage

The `Stack` type implements the following methods:

- [`==(x::Stack, y::Stack)`](@ref)
- [`eltype(::Type{Stack{T}}) where {T}`](@ref)
- [`empty!(s::Stack)`](@ref)
- [`first(s::Stack)`](@ref)
- [`isempty(s::Stack)`](@ref)
- [`length(s::Stack)`](@ref)
- [`pop!(s::Stack)`](@ref)
- [`push!(s::Stack, x)`](@ref)

----------

```@autodocs
Modules = [DataStructures]
Pages = ["src/stack.jl"]
Order = [:function]
```

```@meta
DocTestSetup = nothing
```
