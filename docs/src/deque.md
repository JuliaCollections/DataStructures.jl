# Deque

The `Deque` type implements a double-ended queue using a list of blocks.
This data structure supports constant-time insertion/removal of elements
at both ends of a sequence.

Usage:

```julia
a = Deque{Int}()
isempty(a)          # test whether the dequeue is empty
length(a)           # get the number of elements
push!(a, 10)        # add an element to the back
pop!(a)             # remove an element from the back
pushfirst!(a, 20)   # add an element to the front
popfirst!(a)        # remove an element from the front
first(a)            # get the element at the front
last(a)             # get the element at the back
```

*Note:* Julia's `Vector` type also provides this interface, and thus can
be used as a deque. However, the `Deque` type in this package is
implemented as a list of contiguous blocks (default size = 2K). As a
deque grows, new blocks may be created and linked to existing blocks.
This way avoids the copying when growing a vector.

Benchmark shows that the performance of `Deque` is comparable to
`Vector` on `push!`, and is noticeably faster on `pushfirst!` (by about
30% to 40%).
