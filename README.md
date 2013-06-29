# DataStructures.jl

This package implements a variety of data structures, including

* Dequeue (based on block-list)
* Stack
* Queue
* Disjoint Sets
* Binary Heap
* Mutable Binary Heap

## Deque

The ``Deque`` type implements a dequeue using a list of blocks. This data structure supports constant-time insertion/removal of elements at both ends of a sequence.

Usage:
```julia
a = Deque{Int}()
isempty(a)          # test whether the dequeue is empty
length(a)           # get the number of elements
push!(a, 10)        # add an element to the back
pop!(a)             # remove an element from the back
unshift!(a, 20)     # add an element to the front
shift!(a)           # remove an element from the front
front(a)            # get the element at the front
back(a)             # get the element at the back
```

*Note:* Julia's ``Vector`` type also provides this interface, and thus can be used as a dequeue. However, the ``Dequeue`` type in this package is implemented as a list of contiguous blocks (default size = 2K). As a dequeue grows, new blocks may be created and linked to existing blocks. This way avoids the copying when growing a vector.

Benchmark shows that the performance of ``Dequeue`` is comparable to ``Vector`` on ``push!``, and is noticeably faster on ``unshift!`` (by about 30% to 40%).


## Stack and Queue

The ``Stack`` and ``Queue`` types are a light-weight wrapper of a dequeue type, which respectively provide interfaces for FILO and FIFO access.

Usage of Stack:
```
s = stack(Int)
push!(s, x)
x = top(s)
x = pop!(s)
``` 

Usage of Queue:
```
q = queue(Int)
enqueue!(q, x)
x = front(q)
x = back(q)
x = dequeue!(q)
```

## Disjoint Sets

Some algorithms, such as finding connected components in undirected graph and Kruskal's method of finding minimum spanning tree, require a data structure that can efficiently represent a collection of disjoint subsets. 
A widely used data structure for this purpose is the *Disjoint set forest*. 

Usage:
```
a = IntDisjointSet(10)      # creates a forest comprised of 10 singletons
union!(a, 3, 5)             # merges the sets that contain 3 and 5 into one
in_same_set(a, x, y)        # determines whether x and y are in the same set
```

One may also use other element types
```
a = DisjointSet{String}(["a", "b", "c", "d"])
union!(a, "a", "b")
in_same_set(a, "c", "d")
```

Note that the internal implementation of ``IntDisjointSet`` is based on vectors, and is very efficient. ``DisjointSet{T}`` is a wrapper of ``IntDisjointSet``, which uses a dictionary to map input elements to an internal index. 


## Heaps

Heaps are data structures that efficiently maintain the minimum (or maximum) for a set of data that may dynamically change. 

All heaps in this package are derived from ``AbstractHeap``, and provides the following interface:

```julia
let h be a heap, i be a handle, and v be a value.

- length(h)         # returns the number of elements

- isempty(h)        # returns whether the heap is empty

- push!(h, v)       # add a value to the heap

- top(h)            # return the top value of a heap

- pop!(h)           # removes the top value, and returns it
```

Mutable heaps (values can be changed after being pushed to a heap) are derived from 
``AbstractMutableHeap <: AbstractHeap``, and additionally provides the following interface:

```julia
- i = push!(h, v)       # adds a value to the heap and and returns a handle to v
                    
- update!(h, i, v)      # updates the value of an element (referred to by the handle i)
```

Currently, the the binary heap (type ``BinaryHeap``) and the mutable binary heap (type ``MutableBinaryHeap``) has been implemented. 

Examples of constructing a heap:
```julia
h = binary_heap(Int)            # creates an empty binary heap of integers
h = binary_heap([1,4,3,2])      # creates a heap from a vector
h = mutable_binary_heap(Int)    # creates an empty mutable binary heap
h = mutable_binary_heap(Int)    # creates a mutable heap from a vector
```
