# Heaps

Heaps are data structures that efficiently maintain the minimum (or
maximum) for a set of data that may dynamically change.

All heaps in this package are derived from `AbstractHeap`, and provide
the following interface:

```julia
# Let `h` be a heap, `v` be a value, and `n` be an integer size

length(h)            # returns the number of elements

isempty(h)           # returns whether the heap is empty

push!(h, v)          # add a value to the heap

first(h)             # return the first (top) value of a heap

pop!(h)              # removes the first (top) value, and returns it

extract_all!(h)      # removes all elements and returns sorted array

extract_all_rev!(h)  # removes all elements and returns reverse sorted array

sizehint!(h, n)      # reserve capacity for at least `n` elements
```

Mutable heaps (values can be changed after being pushed to a heap) are
derived from `AbstractMutableHeap <: AbstractHeap`, and additionally
provides the following interface:

```julia
# Let `h` be a heap, `i` be a handle, and `v` be a value.

i = push!(h, v)            # adds a value to the heap and and returns a handle to v

update!(h, i, v)           # updates the value of an element (referred to by the handle i)

delete!(h, i)              # deletes the node with handle i from the heap

v, i = top_with_handle(h)  # returns the top value of a heap and its handle
```

Currently, both min/max versions of binary heap (type `BinaryHeap`) and
mutable binary heap (type `MutableBinaryHeap`) have been implemented.

Examples of constructing a heap:

```julia
h = BinaryMinHeap{Int}()
h = BinaryMaxHeap{Int}()             # create an empty min/max binary heap of integers

h = BinaryMinHeap([1,4,3,2])
h = BinaryMaxHeap([1,4,3,2])         # create a min/max heap from a vector

h = MutableBinaryMinHeap{Int}()
h = MutableBinaryMaxHeap{Int}()      # create an empty mutable min/max heap

h = MutableBinaryMinHeap([1,4,3,2])
h = MutableBinaryMaxHeap([1,4,3,2])  # create a mutable min/max heap from a vector
```

## Using alternate orderings

Heaps can also use alternate orderings apart from the default one defined by
`Base.isless`. This is accomplished by passing an instance of `Base.Ordering`
as the first argument to the constructor. The top of the heap will then be the
element that comes first according to this ordering.

The following example uses 2-tuples to track the index of each element in the
original array, but sorts only by the data value:

```julia
data = collect(enumerate(["foo", "bar", "baz"]))

h1 = BinaryHeap(data) # Standard lexicographic ordering for tuples
first(h1)             # => (1, "foo")

h2 = BinaryHeap(Base.By(last), data) # Order by 2nd element only
first(h2)                            # => (2, "bar")
```

If the ordering type is a singleton it can be passed as a type parameter to the
constructor instead:

```julia
BinaryHeap{T, O}()        # => BinaryHeap{T}(O())
MutableBinaryHeap{T, O}() # => MutableBinaryHeap{T}(O())
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

The usual `first(h)` and `pop!(h)` are defined to be `minimum(h)` and `popmin!(h)`,
respectively.

This package includes an implementation of a binary min-max heap (`BinaryMinMaxHeap`).
> Atkinson, M.D., Sack, J., Santoro, N., & Strothotte, T. (1986). Min-Max > Heaps and Generalized Priority Queues. Commun. ACM, 29, 996-1000.
> doi: [10.1145/6617.6621](https://doi.org/10.1145/6617.6621)

Examples:
```julia
h = BinaryMinMaxHeap{Int}()        # create an empty min-max heap with integer values

h = BinaryMinMaxHeap([1, 2, 3, 4]) # create a min-max heap from a vector
```

# Functions using heaps

Heaps can be used to extract the largest or smallest elements of an
array without sorting the entire array first:

```julia
data = [0,21,-12,68,-25,14]
nlargest(3, data)  # => [68,21,14]
nsmallest(3, data) # => [-25,-12,0]
```

Both methods also support the `by` and `lt` keywords to customize the sort order,
as in `Base.sort`:

```julia
nlargest(3, data, by=x -> x^2)  # => [68,-25,21]
nsmallest(3, data, by=x -> x^2) # => [0,-12,14]
```

The lower-level `DataStructures.nextreme` function takes a `Base.Ordering`
instance as the first argument and returns the first `n` elements according to
this ordering:

```julia
DataStructures.nextreme(Base.Forward, n, a) # Equivalent to nsmallest(n, a)
```


# Improving performance with Float data

One use case for custom orderings is to achieve faster performance with `Float`
elements with the risk of random ordering if any elements are `NaN`.
The provided `DataStructures.FasterForward` and `DataStructures.FasterReverse`
orderings are optimized for this purpose and may achive a 2x performance boost:

```julia
h = BinaryHeap{Float64, DataStructures.FasterForward}() # faster min heap
h = BinaryHeap{Float64, DataStructures.FasterReverse}() # faster max heap

h = MutableBinaryHeap{Float64, DataStructures.FasterForward}() # faster mutable min heap
h = MutableBinaryHeap{Float64, DataStructures.FasterReverse}() # faster mutable max heap

DataStructures.nextreme(DataStructures.FasterReverse(), n, a)  # faster nlargest(n, a)
DataStructures.nextreme(DataStructures.FasterForward(), n, a)  # faster nsmallest(n, a)
```
