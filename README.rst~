=================
DataStructures.jl
=================

[![Build Status](https://travis-ci.org/JuliaLang/DataStructures.jl.svg?branch=master)](https://travis-ci.org/JuliaLang/DataStructures.jl)

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
* Sorted Dictionary
* Multimap
* Sorted Set

-----
Deque
-----

The ``Deque`` type implements a double-ended queue using a list of blocks. This data structure supports constant-time insertion/removal of elements at both ends of a sequence.

Usage::

  a = Deque{Int}()
  isempty(a)          # test whether the dequeue is empty
  length(a)           # get the number of elements
  push!(a, 10)        # add an element to the back
  pop!(a)             # remove an element from the back
  unshift!(a, 20)     # add an element to the front
  shift!(a)           # remove an element from the front
  front(a)            # get the element at the front
  back(a)             # get the element at the back


*Note:* Julia's ``Vector`` type also provides this interface, and thus can be used as a deque. However, the ``Deque`` type in this package is implemented as a list of contiguous blocks (default size = 2K). As a deque grows, new blocks may be created and linked to existing blocks. This way avoids the copying when growing a vector.

Benchmark shows that the performance of ``Deque`` is comparable to ``Vector`` on ``push!``, and is noticeably faster on ``unshift!`` (by about 30% to 40%).

---------------
Stack and Queue
---------------

The ``Stack`` and ``Queue`` types are a light-weight wrapper of a deque type, which respectively provide interfaces for FILO and FIFO access.

Usage of Stack::

  s = Stack(Int)
  push!(s, x)
  x = top(s)
  x = pop!(s)


Usage of Queue::

  q = Queue(Int)
  enqueue!(q, x)
  x = front(q)
  x = back(q)
  x = dequeue!(q)

-------------------------
Accumulators and Counters
-------------------------

A accumulator, as defined below, is a data structure that maintains an accumulated number for each key. This is a counter when the accumulated values reflect the counts::


  type Accumulator{K, V<:Number}
      map::Dict{K, V}
  end

There are different ways to construct an accumulator/counter::


  a = accumulator(K, V)    # construct an accumulator with key-type K and 
                           # accumulated value type V
 
  a = accumulator(dict)    # construct an accumulator from a dictionary
 
  a = counter(K)           # construct a counter, i.e. an accumulator with
                           # key type K and value type Int

  a = counter(dict)        # construct a counter from a dictionary

  a = counter(seq)         # construct a counter by counting keys in a sequence


Usage of an accumulator/counter::

  # let a and a2 be accumulators/counters
  
  a[x]             # get the current value/count for x. 
                   # if x was not added to a, it returns zero(V)

  push!(a, x)       # add the value/count for x by 1
  push!(a, x, v)    # add the value/count for x by v
  push!(a, a2)      # add all counts from a2 to a1
 
  pop!(a, x)       # remove a key x from a, and returns its current value

  merge(a, a2)     # return a new accumulator/counter that combines the
                   # values/counts in both a and a2


-------------
Disjoint Sets
-------------

Some algorithms, such as finding connected components in undirected graph and Kruskal's method of finding minimum spanning tree, require a data structure that can efficiently represent a collection of disjoint subsets. 
A widely used data structure for this purpose is the *Disjoint set forest*. 

Usage::

  a = IntDisjointSets(10)      # creates a forest comprised of 10 singletons
  union!(a, 3, 5)             # merges the sets that contain 3 and 5 into one
  in_same_set(a, x, y)        # determines whether x and y are in the same set
  elem = push!(a)             # adds a single element in a new set; returns the new element 
                              # (this operation is often called MakeSet)


One may also use other element types::

  a = DisjointSets{String}(["a", "b", "c", "d"])
  union!(a, "a", "b")
  in_same_set(a, "c", "d")
  push!(a, "f")

Note that the internal implementation of ``IntDisjointSets`` is based on vectors, and is very efficient. ``DisjointSets{T}`` is a wrapper of ``IntDisjointSets``, which uses a dictionary to map input elements to an internal index. 


-----
Heaps
-----

Heaps are data structures that efficiently maintain the minimum (or maximum) for a set of data that may dynamically change. 

All heaps in this package are derived from ``AbstractHeap``, and provides the following interface::

  # Let h be a heap, i be a handle, and v be a value.

  length(h)         # returns the number of elements

  isempty(h)        # returns whether the heap is empty

  push!(h, v)       # add a value to the heap

  top(h)            # return the top value of a heap

  pop!(h)           # removes the top value, and returns it


Mutable heaps (values can be changed after being pushed to a heap) are derived from 
``AbstractMutableHeap <: AbstractHeap``, and additionally provides the following interface::


  i = push!(h, v)       # adds a value to the heap and and returns a handle to v
                    
  update!(h, i, v)      # updates the value of an element (referred to by the handle i)

Currently, both min/max versions of binary heap (type ``BinaryHeap``) and mutable binary heap (type ``MutableBinaryHeap``) have been implemented.

Examples of constructing a heap::

  h = binary_minheap(Int)            
  h = binary_maxheap(Int)            # create an empty min/max binary heap of integers

  h = binary_minheap([1,4,3,2])      
  h = binary_maxheap([1,4,3,2])      # create a min/max heap from a vector

  h = mutable_binary_minheap(Int)    
  h = mutable_binary_maxheap(Int)    # create an empty mutable min/max heap

  h = mutable_binary_minheap([1,4,3,2])    
  h = mutable_binary_maxheap([1,4,3,2])    # create a mutable min/max heap from a vector


----------------------------
OrderedDicts and OrderedSets
----------------------------

``OrderedDicts`` are simply dictionaries whose entries have a
particular order.  For ``OrderedDicts`` (and ``OrderedSets``), order
refers to *insertion order*, which allows deterministic iteration over
the dictionary or set::


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


All standard ``Associative`` and ``Dict`` functions are available for
``OrderedDicts``, and all ``Set`` operations are available for
OrderedSets.

Note that to create an OrderedSet of a particular type, you must
specify the type in curly-braces::

  # create an OrderedSet of Strings
  strs = OrderedSet{String}()



----------------------------------
DefaultDict and DefaultOrderedDict
----------------------------------

A DefaultDict allows specification of a default value to return when a requested key is not in a dictionary.

While the implementation is slightly different, a ``DefaultDict`` can be thought to provide a normal ``Dict``
with a default value.  A ``DefaultOrderedDict`` does the same for an ``OrderedDict``.

Constructors::

  DefaultDict(default, kv)                        # create a DefaultDict with a default value or function,
                                                  # optionally wrapping an existing dictionary
										        # or array of key-value pairs

  DefaultDict(KeyType, ValueType, default)        # create a DefaultDict with Dict type (KeyType,ValueType)

  DefaultOrderedDict(default, kv)                 # create a DefaultOrderedDict with a default value or function,
                                                  # optionally wrapping an existing dictionary
  							  	                # or array of key-value pairs

  DefaultOrderedDict(KeyType, ValueType, default) # create a DefaultOrderedDict with Dict type (KeyType,ValueType)


Examples using ``DefaultDict``::

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


Note that in the last example, we need to use a function to create each new ``DefaultDict``.
If we forget, we will end up using the same ``DefaultDict`` for all default values::


  julia> dd = DefaultDict(String, DefaultDict, DefaultDict(String,Int,0));
  
  julia> dd["a"]
  DefaultDict{String,Int64,Int64,Dict{K,V}}()

  julia> dd["b"]["a"] = 1
  1

  julia> dd["a"]
  ["a"=>1]


----
Trie
----

An implementation of the `Trie` data structure. This is an associative structure, with `String` keys::

  t=Trie{Int}()
  t["Rob"]=42
  t["Roger"]=24
  haskey(t,"Rob") #true
  get(t,"Rob",nothing) #42
  keys(t) # "Rob", "Roger"

-----------
Linked List
-----------

A list of sequentially linked nodes. This allows efficient insertion of nodes to the front of the list::

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

------------------------------
Sorted Containers: Overview
------------------------------

Three sorted containers are provided:
SortedDict, MultiMap and SortedSet.
*SortedDict* is similar to the built-in Julia type Dict
except with the additional feature that the keys are stored in
sorted order and can be efficiently iterated in this order.
*MultiMap* is also like Dict except that the same key
may occur multiple times, each time with a different (or the same)
value.  Finally *SortedSet* is similar to the built-in Set with
the feature that
the entries are stored in sorted
order and can be efficiently iterated in this order.
SortedDict is a subtype of Associative; MultiMap and SortedSet
are currently subtypes only of Any.  (There is a proposal
to create an abstract set type in Julia, in which case SortedSet will
become a subtype of that.)

All three data structures internally use 2-3 trees.  A 2-3 tree is a
kind of balanced tree and is described in many elementary data
structure textbook.

The type of the key for all three containers must support an
``isless`` comparison operation.  This operation must be transitive
(i.e., ``isless(a,b)`` and ``isless(b,c)`` imply ``isless(a,c)``)
and anti-symmetric (i.e., ``isless(a,b)`` implies ``!isless(b,a)``).
Equality between ``a`` and ``b`` is assumed to hold iff 
``!isless(a,b)`` and ``!isless(b,a)`` both hold.  The user must provide
an ``isless`` method for the key type
if it is not already built in.  (Many common key types
such as numbers and strings already have a transitive and anti-symmetric
``isless`` method).  

The code also requires a function called ``isequal_l`` which must have the
property that ``isequal_l(a,b)`` if and only if
``!isless(a,b) && !isless(b,a)``.  For many data types, the function
``isequal`` has this property, so that the user may simply define
``isequal_l`` to be the same as ``isequal``.  However, this equivalance
is not guaranteed by Julia, so the package defines a default implementation::

  isequal_l(a,b) = !isless(a,b) && !isless(b,a)

in case the user does not provide a more efficient version of ``isequal_l.``

------------------------------
Indices for Sorted Containers
------------------------------


All three containers are accompanied by an auxiliary type called the *index*.  
The names for these types are ``SortedDictIndex{K,V}``, ``MultiMapIndex{K,V}``
and ``SortedSetIndex{K}``.
This index is analogous to an array subscript; it provides
the address of a specific (key,value) pair (in the case of SortedDict
and MultiMap) or key (in the case of Sorted Set) and can be
dereferenced in O(1) time.  (For readers familiar with C++ standard
containers, this notion of index is similar to the C++ iterator.  The
main difference is that indices in this package are array subscripts and
cannot be dereferenced without knowledge of the container, whereas C++ iterators
are essentially memory addresses that can be dereferenced by themselves.)
An index can be advanced or regressed via the functions 
``advance_ind`` and ``regress_ind``.  There are two special values that
the index may take: the *before-start* value and the *past-end* value.  These special
values act as lower and upper bounds
on the actual data.  The before-start index can be advanced,
while the past-end index can be regressed.  A dereferencing operation on either
leads to an error.  In the current release, an index is stored
as an integer.

----------------------------------
Constructors for sorted containers
----------------------------------

``SortedDict(d)``
  Argument ``d`` is an ordinary Julia dict (or any associative type)
  used to initialize the contained, e.g.::

     c = SortedDict(["New York" => 1788, "Illinois" => 1818])

  In this example the key-type is deduced to be ASCIIString, while the
  value-type is Int. An
  empty SortedDict is created by using an empty but typed value of ``d``
  as the argument, e.g., ``t = SortedDict((ASCIIString=>Int)[])``.

``MultiMap(karray, varray)``
  Argument ``karray`` is a 1-dimensional array of keys while ``varray`` is
  a 1-dimensional array of values.  The two arrays must be the same length.
  An empty MultiMap is initialized by specifying two empty but typed arrays,
  e.g., ``t = MultiMap(Int[], Float64[])``.  The arrays can be any subtype
  of ``AbstractArray``.

``SortedSet(karray)``
  Argument ``karray`` is a 1-dimensional array of keys.  An empty set is
  initialized by specifying an empty but typed array.  

---------------------------------
Complexity of sorted containers
---------------------------------

In the list of functions below, the complexity of the various
operations is given.  For example, O(log *n*) means that the function
requires a number of operations
logarithmic in *n*, where *n* is the current size 
(number of items) of the
container at the time of the function call.  Note that comparing
two keys is considered one 'operation' in this context, even though
there are settings where comparing two keys could be expensive.


---------------------------------
Navigating the containers
---------------------------------
``m[k]``
  Argument ``m`` is a SortedDict and ``k`` is a key.  On the right-hand side
  of an expression, this retrieves the value associated with the key
  (or ``KeyError`` if none).  On the left-hand side, this assigns or
  reassigns the value associated with the key.  (For assigning and reassigning,
  see also ``ind_insert!`` below.)  Time: O(log *n*)

``ind_find(m,k)``
  Argument ``m`` is a SortedDict or SortedSet and argument ``k`` is a key.
  This function returns the index of ``k`` in the container, or the
  past-end marker if ``k`` is absent. Time: O(log *n*)


``ind_findrange(m,k)``
  Argument ``m`` is a MultiMap and ``k`` is a key.  This function returns
  a pair of indices, one for the first occurrence of key ``k`` and the second
  for the first occurrence of a key greater than ``k`` (suitable for a loop
  using the ``multimap_range_iteration`` below.  If ``k`` is absent, then
  two past-end indices are returned. Time: O(log *n*)

``deref_ind(m,i)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet, while ``i``
  is an index.  This returns the (key,value) pair (for SortedDict and MultiMap)
  or key (for SortedSet) pointed to by the index.  Time: O(1)

``deref_key_only_ind(m,i)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet, while ``i``
  is an index.  This returns the key pointed to by the index.  
  (Thus, for SortedSet, deref_ind and deref_key_only are identical.)
  Time: O(1)

``ind_first(m)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet.  This function
  returns the index of the first item according
  to the sorted order in the container.  If the container is empty,
  it returns the past-end index. Time: O(log *n*)

``endof(m)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet.  This function
  returns the index of the last item according
  to the sorted order in the container.  If the container is empty,
  it returns the before-start index.  Time: O(log *n*)

``first(m)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet.  This function
  returns the first item (a ``(k,v)`` pair for SortedDict or MultiMap;
  a key for SortedSet) according
  to the sorted order in the container.  Thus, ``first(m)`` is
  equivalent to ``deref_ind(m, ind_first(m))``.
  It is an error to call this
  function on an empty container. Time: O(log *n*)

``last(m)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet.  This function
  returns the last item (a ``(k,v)`` pair for SortedDict or MultiMap;
  a key for SortedSet) according
  to the sorted order in the container.  Thus, ``last(m)`` is
  equivalent to ``deref_ind(m, endof(m))``.
  It is an error to call this
  function on an empty container.  Time: O(log *n*)

``past_end(m)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet.  This
  function returns the past-end index.  Time: O(1)

``is_ind_past_end(m, i)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet, and 
  ``i`` is an index.  This
  function tests whether the index is past-end for the container. 
  Equivalent to ``i == past_end(m)``.  Time: O(1)

``before_start(m)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet.  This
  function returns the before-start index.  Time: O(1)

``is_ind_before_start(m, i)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet, and 
  ``i`` is an index.  This
  function tests whether the index is before-start for the container. 
  Equivalent to ``i == before_start(m)``.  Time: O(1)


``advance_ind(m, i)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet and
  ``i`` is an index.  This function returns the index of the
  next entry in the container according to the sort order of the
  keys.  After the last item, this routine returns the past-end
  index.  It is an error to invoke this function if ``i`` is the
  past-end index.  If ``i`` is the before-start index, then this
  routine returns the index of the first item in the sort order (i.e., the
  same index returned by the ``ind_first`` function).
  Time: O(log *n*)

``regress_ind(m, i)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet and
  ``i`` is an index.  This function returns the index of the
  previous entry in the container according to the sort order of the
  keys.  If ``i`` indexes the first item, this routine returns the before-start
  index.  It is an error to invoke this function if ``i`` is the
  before-start index.  If ``i`` is the past-end index, then this
  routine returns the index of the last item in the sort order (i.e., the
  same index returned by the ``endof`` function).
  Time: O(log *n*)

``ind_equal_or_greater(m,k)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet and
  ``k`` is an element of the key type.  This routine returns the index
  of the first item in the container whose key is equal to or greater
  than ``k``.  If there is no such key, then the past-end index
  is returned.
  Time: O(log *n*)

``ind_greater(m,k)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet and
  `k`` is an element of the key type.  This routine returns the index
  of the first item in the container whose key is greater 
  than ``k``.  If there is no such key, then the past-end 
  index  is returned.
  Time: O(log *n*)


--------------------------------------------
Inserting & Deleting for sorted containers
--------------------------------------------

``empty!(m)``
    Argument ``m`` is a SortedDict, MultiMap or SortedSet.  This
    empties the container.  Time: O(1).

``ind_insert!(m,k,v)``
  Argument ``m`` is a SortedDict or Multimap, ``k`` is a key and ``v``
  is the corresponding value.  This inserts the ``(k,v)`` pair into
  the container.  If the key is already present, SortedDict overwrites
  the old value, while MultiMap inserts the new value at the end of
  the sequence of records with the same key.  For SortedDict the return
  value is a pair whose first entry is boolean and indicates whether
  the insertion was new (i.e., the key was not previously present) and
  the second entry is the index of the new entry.  For MultiMap, only
  the index is returned.
  Time: O(log *n*)


``ind_insert!(m,k)``
  Argument ``m`` is a SortedSet.  This function returns a pair
  whose first entry is boolean and indicates whether
  the insertion was new (i.e., the key was not previously present) and
  the second entry is the index of the new entry.
  Time: O(log *n*)

``delete_ind!(m,i)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet and
  ``i`` is an index.  This operation deletes the item
  (either (key,value) pair for SortedDict and MultiMap or
  key for SortedSet) indexed by ``i``.  It is an error to call
  this on an entry that has already been deleted or on the
  before-start or past-end indices.  After this operation is 
  complete, ``i`` is an invalid index and cannot be used in
  any further operations.
  Time: O(log *n*)

``delete!(m,k)``
  Argument ``m`` is a SortedDict, MultiMap or SortedSet and
  ``k`` is a key.  This operation deletes the item
  (either (key,value) pair for SortedDict or
  key for SortedSet) whose key is ``k``.  It is an error 
  if ``k`` is not a key of an item in the container.
  After this operation is 
  complete, any index addressing the deleted item is invalid.
  Time: O(log *n*)

``push!(m,k)``
  Argument ``m`` is a SortedSet.  This function inserts ``k`` into ``m``.
  If ``k`` is already in ``m``, nothing happens.  This function returns ``m``.
  Time: O(log *n*)  

``pop!(m,k)``
  Deletes the item with key ``k`` in SortedDict ``m`` and returns
  the value that was associated with ``k``.  A ``KeyError`` results
  if ``k`` is not in ``m``.
  Time: O(log *n*)

--------------------------------
Iteration over sorted containers
--------------------------------

As is standard in Julia, iteration over the containers is
implemented via calls to three functions, ``start``,
``next`` and ``done``.  It is usual practice, however, to
call these functions implicitly with a for-loop rather than
explicitly, so they are presented here in for-loop notation.
Internally, all of these iterations are implemented with indices
that are advanced via the ``advance_ind`` operation.  Each iteration
of these loops requires O(log *n*) operations to advance the
index.

-----------------------------------
Iterating over an entire container
-----------------------------------
The following loops over the entire container ``m``, where
``m`` is a SortedDict, MultiMap or SortedSet::

  for p = m
     < body >
  end

In this loop, ``p`` takes on successive (key,value) pairs (or
keys in the case of SortedSet) according to 
the sort order of the key.

------------------------------------------------------
Iterating over an entire container retrieving indices
------------------------------------------------------
The following loops over the entire container ``m``, where
``m`` is a SortedDict, MultiMap or SortedSet::

  for p = enumerate_ind(m)
     < body >
  end

In this loop, ``p`` takes on successive (index, (key,value)) pairs (or
(index, key) in the case of SortedSet) according to 
the sort order of the key.  Note that the following loop is safe::

  for p = enumerate_ind(m)
     delete_ind!(m, p[1])
  end

because the next value of the index (after ``p[1]``) is computed 
at the beginning of the loop body before ``p[1]`` is deleted, and hence
``p[1]`` is still valid at the time it is advanced.

----------------------------------------
Iterating over a subrange of a container
----------------------------------------

It is possible to iterate over a subrange of a container as follows::

   for p = sorted_dict_range_iteration(m, startind, endind)
     < body >
   end

   for p = multimap_range_iteration(m, startind, endind)
     < body >
   end

   for p = sorted_set_range_iteration(m, startind, endind)
     < body >
   end

In these three loops ``m`` is, respectively, a SortedDict, MultiMap, and SortedSet.
As well as taking the container ``m`` as an argument, they take two indices
that specify the first index and the last.  The loop body is executed
for the first index and all subsequent up to and not including the
``endind`` index.  So, for example, if ``startind==endind``, then the body is never
executed.  The loop also terminates if the past-end marker is reached.

Within the loop body ``p`` takes successive (key,value) pairs as its value
in the first two loops, and success key values in the last loop.

If the ``endind`` index comes before the ``startind`` index, then the loop
continues until the past-end marker.  It is an error if ``startind`` is equal
to the before-start index because that index cannot be dereferenced.  if
``startind`` is the past-end marker, then the body never executes.

The following versions of these loops retrieve the indices as well; 
for these loops, ``p`` takes on successive (index,(key,value)) values
in the first two, and successive (index,key) values in the third::

   for p = enumerate_ind(sorted_dict_range_iteration(m, startind, endind))
     < body >
   end

   for p = enumerate_ind(multimap_range_iteration(m, startind, endind))
     < body >
   end

   for p = enumerate_ind(sorted_set_range_iteration(m, startind, endind))
     < body >
   end

--------------------------
Keys and values iteration
--------------------------

In order to be compatible with associative types, SortedDict also has
keys and values iterations which are as follows.  In all of these,
``m`` is a SortedDict::

   for k = keys(m)
      < body >
   end

   for v = values(m)
      < body >
   end

   for p = enumerate_ind(keys(m))
      < body >
   end

   for p = enumerate_ind(values(m))
      < body >
   end

The first two loop over keys and values (resp.) of m.  In the second two,
``p`` is an (index,key) and (index,value) (resp.) pair.




----------------
Other functions
----------------


``isempty(m)``
  Returns ``true`` if the container is empty (no items).
  Time: O(1)

``length(m)``
  Returns the length, i.e., number of items, in the container.
  Time: O(1)

``in(p,m)``
  Returns true if ``p`` is in ``m``, where ``m`` is a SortedDict or
  SortedSet, and ``p`` is a (key,value) pair (for SortedDict) or
  key (for SortedSet).  Not implemented for MultiMap because there
  is no logarithmic way to check this for MultiMap.  Time: O(log *n*)

``eltype(m)``
  Returns the (key,value) type for SortedDict and MultiMap, and the
  key type for SortedSet.  Time: O(1)

``haskey(m,k)``
  Returns true if ``k`` is present for SortedDict or MultiMap ``m``.  Not
  implemented for SortedSet.  
  Time: O(log *n*)


``get(m,k,v)``
  Returns the value associated with key ``k`` where ``m`` is a SortedDict,
  or else returns ``v`` if ``k`` is not in ``m``.
  Time: O(log *n*)

``get!(m,k,v)``
  Returns the value associated with key ``k`` where ``m`` is a SortedDict,
  or else returns ``v`` if ``k`` is not in ``m``, and in the latter case,
  inserts ``(k,v)`` into ``m``.
  Time: O(log *n*)

``getkey(m,k,defaultk)``
  Returns key ``k`` where ``m`` is a SortedDict, if ``k`` is in ``m``
  else it returns ``defaultk``.
  Time: O(log *n*)


``isequal(m1,m2)``
  Checks if two containers are equal in the sense
  that they contain the same items.
  Equality in this sense does not guarantee that indices
  for the first are valid for the second.
  Time: O(*n* log *n*)

``packcopy(m)``
  This returns a copy of ``m`` in which the data is
  packed.  In all of the containers, when deletions take
  place, the previously allocated memory is not returned.
  This function can be used to reclaim memory after
  many deletions.  Indices for ``m`` are not valid
  for the packed copy.
  Time: O(*n* log *n*)

``deepcopy(m)``
  This returns a copy of ``m`` in which the data is
  deep-copied, i.e., the keys and values are replicated
  if they are mutable types.  Indices for ``m`` are valid
  for the deep copy. 
  Time O(*maxn*), where *maxn* denotes the maximum size
  that ``m`` has attained in the past.

``packdeepcopy(m)``
  This returns a packed copy of ``m`` in which the keys
  and values are deep-copied.
  This function can be used to reclaim memory after
  many deletions.  Indices for ``m`` are not valid
  for the packed copy.
  Time: O(*n* log *n*)


``merge(s, t...)``
  This returns a SortedDict that results from merging
  SortedDicts s, t, etc., which all must have the same
  key-value types.  In the case of keys duplicated among
  the arguments, the rightmost argument that owns the
  key gets its value stored.
  Time:  O(*N* log *N*), where *N* is the total size
  of all the arguments.

``union!(s, iterable)``
  Argument ``s`` is a SortedSet, and ``iterable`` is something
  that supports iteration and returns keys.  The keys of 
  ``iterable`` are   inserted into ``s``
  Time: O(*m* log *(m+n)*), where *m* is the length of ``iterable``
  and *n* is the size of ``s``.


``union(s, t...)``
  The arguments are sorted sets of the same type; this
  function computes their union.
  Time: O(*N* log *N*), where *N* is the total size of the
  arguments.

``intersect(s, t...)``
  The arguments are sorted sets of the same type; this
  function computes their intersection.
  Time: O(*N* log *N*), where *N* is the total size of the
  arguments.

``symdiff(s,t)``
  The arguments are sorted sets of the same type; this
  function computes their symmetric difference (i.e., 
  the set of elements that are in one of ``s`` and ``t``
  but not both).
  Time: O(*N* log *N*), where *N* is the total size of the
  arguments.

``setdiff(s,t)``
  The arguments are sorted sets of the same type; this
  function computes the set difference, i.e., elements
  of ``s`` that are not in ``t``.
  Time: O(*N* log *N*), where *N* is the total size of the
  arguments.

``setdiff!(s,iterable)``
  The first argument is a sorted set; the second is
  an iterable item whose iteration returns keys of the
  type for ``s``.  This function deletes all entries of
  ``s`` that are from iterable.
  Time: O(*m* log *n*), where *m* is the number of items
  in ``iterable`` and *n* is the size of ``s``.

``issubset(s,t)``
  The arguments are sorted sets of the same type; this
  function returns ``true`` if each element of ``s``
  also lies in ``t``.  Time: O(*m* log *n*), where
  *m* is the size of ``s`` and *n* is the size of ``t``.

-----------------------------------
Performance of sorted containers
-----------------------------------
Timing tests indicate that the code is about 1.5 to
2 times slower than equivalent C++ code that uses the C++ standard
library containers ``map``, ``multimap`` and ``set``
and compiled with /O2 optimization.  These tests were
conducted on a Windows 8.1 64-bit machine with the
Visual Studio  12.0 compiler.


