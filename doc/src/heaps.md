Heaps
=====

Heaps are data structures that efficiently maintain the minimum (or
maximum) for a set of data that may dynamically change.

All heaps in this package are derived from `AbstractHeap`, and provide
the following interface:

```julia
# Let h be a heap, i be a handle, and v be a value.

length(h)         # returns the number of elements

isempty(h)        # returns whether the heap is empty

push!(h, v)       # add a value to the heap

top(h)            # return the top value of a heap

pop!(h)           # removes the top value, and returns it
```

Mutable heaps (values can be changed after being pushed to a heap) are
derived from `AbstractMutableHeap <: AbstractHeap`, and additionally
provides the following interface:

```julia
i = push!(h, v)              # adds a value to the heap and and returns a handle to v

update!(h, i, v)             # updates the value of an element (referred to by the handle i)

v, i = top_with_handle(h)    # returns the top value of a heap and its handle
```

Currently, both min/max versions of binary heap (type `BinaryHeap`) and
mutable binary heap (type `MutableBinaryHeap`) have been implemented.

Examples of constructing a heap:

```julia
h = binary_minheap(Int)
h = binary_maxheap(Int)            # create an empty min/max binary heap of integers

h = binary_minheap([1,4,3,2])
h = binary_maxheap([1,4,3,2])      # create a min/max heap from a vector

h = mutable_binary_minheap(Int)
h = mutable_binary_maxheap(Int)    # create an empty mutable min/max heap

h = mutable_binary_minheap([1,4,3,2])
h = mutable_binary_maxheap([1,4,3,2])    # create a mutable min/max heap from a vector
```

Functions using heaps
=====================

Heaps can be used to extract the largest or smallest elements of an
array without sorting the entire array first:

```julia
nlargest(3, [0,21,-12,68,-25,14]) # => [68,21,14]
nsmallest(3, [0,21,-12,68,-25,14]) # => [-25,-12,0]
```

`nlargest(n, a)` is equivalent to `sort(a, lt = >)[1:min(n, end)]`, and
`nsmallest(n, a)` is equivalent to `sort(a, lt = <)[1:min(n, end)]`.
