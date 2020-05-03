# CircularDeque

The `CircularDeque` type implements a double-ended queue using a
circular buffer of fixed `capacity`. This data structure supports
constant-time insertion/removal of elements at both ends of a sequence.

Usage:

```julia
a = CircularDeque{Int}(n)   # allocate a deque with maximum capacity n
isempty(a)          # test whether the deque is empty
empty!(a)           # reset the deque
capacity(a)         # return capacity
length(a)           # get the number of elements currently in the deque
push!(a, 10)        # add an element to the back
pop!(a)             # remove an element from the back
pushfirst!(a, 20)   # add an element to the front
popfirst!(a)        # remove an element from the front
first(a)            # get the element at the front
last(a)             # get the element at the back
eltype(a)           # return type of items
```

*Note:* Julia's `Vector` type also provides this interface, and thus can
be used as a deque. However, the `CircularDeque` type in this package is
implemented as a circular buffer, and thus avoids copying elements when
modifications are made to the front of the vector.

Benchmarks show that the performance of `CircularDeque` is several times
faster than `Deque`.
