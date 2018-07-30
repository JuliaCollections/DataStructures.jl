# CircularBuffer

The `CircularBuffer` type implements a circular buffer of fixed
`capacity` where new items are pushed to the back of the list,
overwriting values in a circular fashion.

Usage:

```julia
cb = CircularBuffer{Int}(n)   # allocate an Int buffer with maximum capacity n
isfull(cb)           # test whether the buffer is full
isempty(cb)          # test whether the buffer is empty
empty!(cb)           # reset the buffer
capacity(cb)         # return capacity
length(cb)           # get the number of elements currently in the buffer
size(cb)             # same as length(cb)
push!(cb, 10)        # add an element to the back and overwrite front if full
pop!(cb)             # remove the element at the back
pushfirst!(cb, 10)   # add an element to the front and overwrite back if full
popfirst!(cb)        # remove the element at the front
append!(cb, [1, 2, 3, 4])     # push at most last `capacity` items
convert(Vector{Float64}, cb)  # convert items to type Float64
eltype(cb)           # return type of items
cb[1]                # get the element at the front
cb[end]              # get the element at the back
fill!(cb, data)      # grows the buffer up-to capacity, and fills it entirely, preserving existing elements.
```
