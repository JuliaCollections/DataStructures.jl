# DataStructures.jl

[![Build Status](https://travis-ci.org/JuliaLang/DataStructures.jl.svg?branch=master)](https://travis-ci.org/JuliaLang/DataStructures.jl)
[![Coverage Status](https://img.shields.io/coveralls/JuliaLang/DataStructures.jl.svg)](https://coveralls.io/r/JuliaLang/DataStructures.jl)
[![DataStructures](http://pkg.julialang.org/badges/DataStructures_release.svg)](http://pkg.julialang.org/?pkg=DataStructures&ver=release)

This package implements a variety of data structures, including

* Deque (based on block-list)
* Stack
* Queue
* Accumulators and Counters
* Disjoint Sets
* Binary Heap
* Mutable Binary Heap
* Ordered Dicts and Sets
* Dictionaries with Defaults
* Trie
* Linked List

## Deque

The ``Deque`` type implements a double-ended queue using a list of blocks. This data structure supports constant-time insertion/removal of elements at both ends of a sequence.

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

*Note:* Julia's ``Vector`` type also provides this interface, and thus can be used as a deque. However, the ``Deque`` type in this package is implemented as a list of contiguous blocks (default size = 2K). As a deque grows, new blocks may be created and linked to existing blocks. This way avoids the copying when growing a vector.

Benchmark shows that the performance of ``Deque`` is comparable to ``Vector`` on ``push!``, and is noticeably faster on ``unshift!`` (by about 30% to 40%).


## Stack and Queue

The ``Stack`` and ``Queue`` types are a light-weight wrapper of a deque type, which respectively provide interfaces for FILO and FIFO access.

Usage of Stack:
```
s = Stack(Int)
push!(s, x)
x = top(s)
x = pop!(s)
```

Usage of Queue:
```
q = Queue(Int)
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

push!(a, x)       # add the value/count for x by 1
push!(a, x, v)    # add the value/count for x by v
push!(a, a2)      # add all counts from a2 to a1

pop!(a, x)       # remove a key x from a, and returns its current value

merge(a, a2)     # return a new accumulator/counter that combines the
                 # values/counts in both a and a2
```


## Disjoint Sets

Some algorithms, such as finding connected components in undirected graph and Kruskal's method of finding minimum spanning tree, require a data structure that can efficiently represent a collection of disjoint subsets.
A widely used data structure for this purpose is the *Disjoint set forest*.

Usage:
```
a = IntDisjointSets(10)      # creates a forest comprised of 10 singletons
union!(a, 3, 5)             # merges the sets that contain 3 and 5 into one
in_same_set(a, x, y)        # determines whether x and y are in the same set
elem = push!(a)             # adds a single element in a new set; returns the new element
                            # (this operation is often called MakeSet)
```

One may also use other element types
```
a = DisjointSets{String}(["a", "b", "c", "d"])
union!(a, "a", "b")
in_same_set(a, "c", "d")
push!(a, "f")
```

Note that the internal implementation of ``IntDisjointSets`` is based on vectors, and is very efficient. ``DisjointSets{T}`` is a wrapper of ``IntDisjointSets``, which uses a dictionary to map input elements to an internal index.


## Heaps

Heaps are data structures that efficiently maintain the minimum (or maximum) for a set of data that may dynamically change.

All heaps in this package are derived from ``AbstractHeap``, and provides the following interface:

```julia
# Let h be a heap, i be a handle, and v be a value.

length(h)         # returns the number of elements

isempty(h)        # returns whether the heap is empty

push!(h, v)       # add a value to the heap

top(h)            # return the top value of a heap

pop!(h)           # removes the top value, and returns it
```

Mutable heaps (values can be changed after being pushed to a heap) are derived from
``AbstractMutableHeap <: AbstractHeap``, and additionally provides the following interface:

```julia
i = push!(h, v)       # adds a value to the heap and and returns a handle to v

update!(h, i, v)      # updates the value of an element (referred to by the handle i)
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

DefaultOrderedDict(default, kv)                 # create a DefaultOrderedDict with a default value or function,
                                                # optionally wrapping an existing dictionary
							  	                # or array of key-value pairs

DefaultOrderedDict(KeyType, ValueType, default) # create a DefaultOrderedDict with Dict type (KeyType,ValueType)
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

##Trie

An implementation of the `Trie` data structure. This is an associative structure, with `String` keys.

```julia
t=Trie{Int}()
t["Rob"]=42
t["Roger"]=24
haskey(t,"Rob") #true
get(t,"Rob",nothing) #42
keys(t) # "Rob", "Roger"
```

Constructors:
```julia
Trie(keys, values)                  # construct a Trie with the given keys and values
Trie(keys)                          # construct a Trie{Nothing} with the given keys and with values = nothing
Trie(kvs::AbstractVector{(K, V)})   # construct a Trie from the given vector of (key, value) pairs
Trie(kvs::Associative{K, V})        # construct a Trie from the given associative structure
```

This package also provides an iterator ``path(t::Trie, str)`` for looping over all the nodes
encountered in searching for the given string ``str``.
This obviates much of the boilerplate code needed in writing many trie algorithms.
For example, to test whether a trie contains any prefix of a given string,
use
```julia
seen_prefix(t::Trie, str) = any(v -> v.is_key, path(t, str))
```

##Linked List

A list of sequentially linked nodes. This allows efficient insertion of nodes to the front of the list.

```julia
julia> l1 = nil()
nil()

julia> l2 = cons(1, l1)
list(1)

julia> l3 = list(2, 3)
list(2, 3)

julia> l4 = cat(l1, l2, l3)
list(1, 2, 3)

julia> l5 = map((x) -> x*2, l4)
list(2, 4, 6)

julia> for i in l5; print(i); end
246

```
