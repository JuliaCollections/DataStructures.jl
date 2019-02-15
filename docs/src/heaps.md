# Heaps

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
h = BinaryMinHeap{Int}()
h = BinaryMaxHeap{Int}()          # create an empty min/max binary heap of integers

h = BinaryMinHeap([1,4,3,2])
h = BinaryMaxHeap([1,4,3,2])      # create a min/max heap from a vector

h = MutableBinaryMinHeap{Int}()
h = MutableBinaryMaxHeap{Int}()   # create an empty mutable min/max heap

h = MutableBinaryMinHeap([1,4,3,2])
h = MutableBinaryMaxHeap([1,4,3,2])    # create a mutable min/max heap from a vector
```

## Min-max heaps
Min-max heaps maintain the minimum _and_ the maximum of a set, 
allowing both to be retrieved in constant (`O(1)`) time.
The min-max heaps in this package are subtypes of `AbstractMinMaxHeap <: AbstractHeap`
and have the same interface as other heaps with the following additions:
```julia
# Let h be a min-max heap, k an integer
minimum(h)     # return the smallest element
maximum(h)     # return the largest element

popmin!(h)     # remove and return the smallest element
popmin!(h, k)  # remove and return the smallest k elements

popmax!(h)     # remove and return the largest element
popmax!(h, k)  # remove and return the largest k elements

popall!(h)     # remove and return all the elements, sorted smallest to largest
popall!(h, o)  # remove and return all the elements according to ordering o
```
The usual `top(h)` and `pop!(h)` are defined to be `minimum(h)` and `popmin!(h)`, 
respectively.

This package includes an implementation of a binary min-max heap (`BinaryMinMaxHeap`).
> Atkinson, M.D., Sack, J., Santoro, N., & Strothotte, T. (1986). Min-Max > Heaps and Generalized Priority Queues. Commun. ACM, 29, 996-1000.
> doi: [10.1145/6617.6621](https://doi.org/10.1145/6617.6621)

Examples:
```julia
h = BinaryMinMaxHeap{Int}()          # create an empty min-max heap with integer values

h = BinaryMinMaxHeap([1, 2, 3, 4]) # create a min-max heap from a vector
```

# Functions using heaps

Heaps can be used to extract the largest or smallest elements of an
array without sorting the entire array first:

```julia
nlargest(3, [0,21,-12,68,-25,14]) # => [68,21,14]
nsmallest(3, [0,21,-12,68,-25,14]) # => [-25,-12,0]
```

`nlargest(n, a)` is equivalent to `sort(a, lt = >)[1:min(n, end)]`, and
`nsmallest(n, a)` is equivalent to `sort(a, lt = <)[1:min(n, end)]`.
