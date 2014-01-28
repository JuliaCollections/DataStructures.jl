# DataStructures.jl

[![Build Status](https://travis-ci.org/lindahua/DataStructures.jl.png)](https://travis-ci.org/lindahua/DataStructures.jl)

This package implements a variety of data structures, including

* Dequeue (based on block-list)
* Stack
* Queue
* Disjoint Sets
* Binary Heap
* Mutable Binary Heap
* Ordered Dicts and Sets
* Dictionaries with Defaults

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

## Accumulators and Counters

A accumulator, as defined below, is a data structure that maintains an accumulated number for each key. This is a counter when the accumulated values reflect the counts. 

```julia
type Accumulator{K, V<:Number}
    map::Dict{K, V}
end
```

There are different ways to construct an accumulator/counter:

```julia
a = accumulator(K, V)    # construct an accumulator with key-type K and 
                         # accumulated value type V

a = accumulator(dict)    # construct an accumulator from a dictionary

a = counter(K)           # construct a counter, i.e. an accumulator with
                         # key type K and value type Int


a = counter(dict)        # construct a counter from a dictionary

a = counter(seq)         # construct a counter by counting keys in a sequence
```

Usage of an accumulator/counter:

```julia
# let a and a2 be accumulators/counters

a[x]             # get the current value/count for x. 
                 # if x was not added to a, it returns zero(V)

add!(a, x)       # add the value/count for x by 1
add!(a, x, v)    # add the value/count for x by v
add!(a, a2)      # add all counts from a2 to a1

pop!(a, x)       # remove a key x from a, and returns its current value

merge(a, a2)     # return a new accumulator/counter that combines the
                 # values/counts in both a and a2
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

Currently, both min/max versions of binary heap (type ``BinaryHeap``) and mutable binary heap (type ``MutableBinaryHeap``) have been implemented.

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

## OrderedDicts and OrderedSets

``OrderedDicts`` are simply dictionaries whose entries have a
particular order.  For ``OrderedDicts`` (and ``OrderedSets``), order
refers to *insertion order*, which allows deterministic iteration over
the dictionary or set.

```julia
d = OrderedDict(Char,Int)
for c in 'a':'e'
    d[c] = c-'a'+1
end
collect(d) # => [('a',1),('b',2),('c',3),('d',4),('e',5)]

s = OrderedSet(π,e,γ,catalan,φ)
collect(s) # => [π = 3.1415926535897...,
           #     e = 2.7182818284590...,
           #     γ = 0.5772156649015...,
		   #     catalan = 0.9159655941772...,
		   #	 φ = 1.6180339887498...]
```

All standard ``Associative`` and ``Dict`` functions are available for
``OrderedDicts``, and all ``Set`` operations are available for
OrderedSets.

Note that to create an OrderedSet of a particular type, you must
specify the type in curly-braces:

```julia
# create an OrderedSet of Strings
strs = OrderedSet{String}()
```


## DefaultDict and DefaultOrderedDict

A DefaultDict allows specification of a default value to return when a requested key is not in a dictionary.

While the implementation is slightly different, a ``DefaultDict`` can be thought to provide a normal ``Dict``
with a default value.  A ``DefaultOrderedDict`` does the same for an ``OrderedDict``.

Constructors:
```julia
DefaultDict(default, kv)                        # create a DefaultDict with a default value or function,
                                                # optionally wrapping an existing dictionary
										        # or array of key-value pairs

DefaultDict(KeyType, ValueType, default)        # create a DefaultDict with Dict type (KeyType,ValueType)

OrderedDefaultDict(default, kv)                 # create a OrderedDefaultDict with a default value or function,
                                                # optionally wrapping an existing dictionary
							  	                # or array of key-value pairs

OrderedDefaultDict(KeyType, ValueType, default) # create a OrderedDefaultDict with Dict type (KeyType,ValueType)
```

Examples using ``DefaultDict``:
```julia
dd = DefaultDict(1)               # create an (Any=>Any) DefaultDict with a default value of 1
dd = DefaultDict(String, Int, 0)  # create a (String=>Int) DefaultDict with a default value of 0

d = ['a'=>1, 'b'=>2]
dd = DefaultDict(0, d)            # provide a default value to an existing dictionary
dd['c'] == 0                      # true
#d['c'] == 0                      # false

dd = DefaultOrderedDict(time)     # call time() to provide the default value for an OrderedDict
dd = DefaultDict(Dict)            # Create a dictionary of dictionaries
                                  # Dict() is called to provide the default value
dd = DefaultDict(()->myfunc())    # call function myfunc to provide the default value

# create a Dictionary of type String=>DefaultDict{String, Int}, where the default of the
# inner set of DefaultDicts is zero
dd = DefaultDict(String, DefaultDict, ()->DefaultDict(String,Int,0))
```

Note that in the last example, we need to use a function to create each new ``DefaultDict``.
If we forget, we will end up using the same ``DefaultDict`` for all default values:

```julia
julia> dd = DefaultDict(String, DefaultDict, DefaultDict(String,Int,0));

julia> dd["a"]
DefaultDict{String,Int64,Int64,Dict{K,V}}()

julia> dd["b"]["a"] = 1
1

julia> dd["a"]
["a"=>1]

```
