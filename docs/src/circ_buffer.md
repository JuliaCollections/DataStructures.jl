# CircularBuffer

The `CircularBuffer` type implements a circular buffer of fixed
`capacity` where new items are pushed to the back of the list,
overwriting values in a circular fashion.

Usage:

```julia
a = CircularBuffer{Int}(n)   # allocate an Int buffer with maximum capacity n
isfull(a)           # test whether the buffer is full
isempty(a)          # test whether the buffer is empty
empty!(a)           # reset the buffer
capacity(a)         # return capacity
length(a)           # get the number of elements currently in the buffer
size(a)             # same as length(a)
push!(a, 10)        # add an element to the back and overwrite front if full
unshift!(a, 10)     # add an element to the front and overwrite back if full
append!(a, [1, 2, 3, 4])    # push at most last `capacity` items
convert(Vector{Float64}, a) # convert items to type Float64
eltype(a)           # return type of items
a[1]                # get the element at the front
a[end]              # get the element at the back
```
