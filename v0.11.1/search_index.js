var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "DataStructures.jl",
    "title": "DataStructures.jl",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#DataStructures.jl-1",
    "page": "DataStructures.jl",
    "title": "DataStructures.jl",
    "category": "section",
    "text": "This package implements a variety of data structures, includingDeque (based on block-list)\nCircularBuffer\nCircularDeque (based on a circular buffer)\nStack\nQueue\nPriority Queue\nAccumulators and Counters\nDisjoint Sets\nBinary Heap\nMutable Binary Heap\nOrdered Dicts and Sets\nDictionaries with Defaults\nTrie\nLinked List\nSorted Dict, Sorted Multi-Dict and Sorted Set\nDataStructures.IntSet"
},

{
    "location": "index.html#Contents-1",
    "page": "DataStructures.jl",
    "title": "Contents",
    "category": "section",
    "text": "Pages = [\n    \"index.md\",\n    \"deque.md\",\n    \"circ_buffer.md\",\n    \"circ_deque.md\",\n    \"stack_and_queue.md\",\n    \"priority-queue.md\",\n    \"accumulators.md\",\n    \"disjoint_sets.md\",\n    \"heaps.md\",\n    \"ordered_containers.md\",\n    \"default_dict.md\",\n    \"trie.md\",\n    \"linked_list.md\",\n    \"intset.md\",\n    \"sorted_containers.md\",\n]"
},

{
    "location": "deque.html#",
    "page": "Deque",
    "title": "Deque",
    "category": "page",
    "text": ""
},

{
    "location": "deque.html#Deque-1",
    "page": "Deque",
    "title": "Deque",
    "category": "section",
    "text": "The Deque type implements a double-ended queue using a list of blocks. This data structure supports constant-time insertion/removal of elements at both ends of a sequence.Usage:a = Deque{Int}()\nisempty(a)          # test whether the dequeue is empty\nlength(a)           # get the number of elements\npush!(a, 10)        # add an element to the back\npop!(a)             # remove an element from the back\npushfirst!(a, 20)   # add an element to the front\npopfirst!(a)        # remove an element from the front\nfront(a)            # get the element at the front\nback(a)             # get the element at the backNote: Julia\'s Vector type also provides this interface, and thus can be used as a deque. However, the Deque type in this package is implemented as a list of contiguous blocks (default size = 2K). As a deque grows, new blocks may be created and linked to existing blocks. This way avoids the copying when growing a vector.Benchmark shows that the performance of Deque is comparable to Vector on push!, and is noticeably faster on unshift! (by about 30% to 40%)."
},

{
    "location": "circ_buffer.html#",
    "page": "CircularBuffer",
    "title": "CircularBuffer",
    "category": "page",
    "text": ""
},

{
    "location": "circ_buffer.html#CircularBuffer-1",
    "page": "CircularBuffer",
    "title": "CircularBuffer",
    "category": "section",
    "text": "The CircularBuffer type implements a circular buffer of fixed capacity where new items are pushed to the back of the list, overwriting values in a circular fashion.Usage:cb = CircularBuffer{Int}(n)   # allocate an Int buffer with maximum capacity n\nisfull(cb)           # test whether the buffer is full\nisempty(cb)          # test whether the buffer is empty\nempty!(cb)           # reset the buffer\ncapacity(cb)         # return capacity\nlength(cb)           # get the number of elements currently in the buffer\nsize(cb)             # same as length(cb)\npush!(cb, 10)        # add an element to the back and overwrite front if full\npop!(cb)             # remove the element at the back\npushfirst!(cb, 10)   # add an element to the front and overwrite back if full\npopfirst!(cb)        # remove the element at the front\nappend!(cb, [1, 2, 3, 4])     # push at most last `capacity` items\nconvert(Vector{Float64}, cb)  # convert items to type Float64\neltype(cb)           # return type of items\ncb[1]                # get the element at the front\ncb[end]              # get the element at the back\nfill!(cb, data)      # grows the buffer up-to capacity, and fills it entirely, preserving existing elements."
},

{
    "location": "circ_deque.html#",
    "page": "CircularDeque",
    "title": "CircularDeque",
    "category": "page",
    "text": ""
},

{
    "location": "circ_deque.html#CircularDeque-1",
    "page": "CircularDeque",
    "title": "CircularDeque",
    "category": "section",
    "text": "The CircularDeque type implements a double-ended queue using a circular buffer of fixed capacity. This data structure supports constant-time insertion/removal of elements at both ends of a sequence.Usage:a = CircularDeque{Int}(n)   # allocate a deque with maximum capacity n\nisempty(a)          # test whether the deque is empty\nempty!(a)           # reset the deque\ncapacity(a)         # return capacity\nlength(a)           # get the number of elements currently in the deque\npush!(a, 10)        # add an element to the back\npop!(a)             # remove an element from the back\npushfirst!(a, 20)   # add an element to the front\npopfirst!(a)        # remove an element from the front\nfront(a)            # get the element at the front\nback(a)             # get the element at the back\neltype(a)           # return type of itemsNote: Julia\'s Vector type also provides this interface, and thus can be used as a deque. However, the CircularDeque type in this package is implemented as a circular buffer, and thus avoids copying elements when modifications are made to the front of the vector.Benchmarks show that the performance of CircularDeque is several times faster than Deque."
},

{
    "location": "stack_and_queue.html#",
    "page": "Stack and Queue",
    "title": "Stack and Queue",
    "category": "page",
    "text": ""
},

{
    "location": "stack_and_queue.html#Stack-and-Queue-1",
    "page": "Stack and Queue",
    "title": "Stack and Queue",
    "category": "section",
    "text": "The Stack and Queue types are a light-weight wrapper of a deque type, which respectively provide interfaces for LIFO and FIFO access.Usage of Stack:s = Stack{Int}()\npush!(s, x)\nx = top(s)\nx = pop!(s)Usage of Queue:q = Queue{Int}()\nenqueue!(q, x)\nx = front(q)\nx = back(q)\nx = dequeue!(q)Both Stack and Queue implement the Iterator interface; iterating over Stack returns items in FILO order and iterating over Queue returns items in FIFO order. There is also a reverse_iter function implemented for both which returns items in the reverse order for each type (i.e. FIFO for Stack and LIFO for Queue)."
},

{
    "location": "priority-queue.html#",
    "page": "Priority Queue",
    "title": "Priority Queue",
    "category": "page",
    "text": ""
},

{
    "location": "priority-queue.html#Priority-Queue-1",
    "page": "Priority Queue",
    "title": "Priority Queue",
    "category": "section",
    "text": "The PriorityQueue type provides a basic priority queue implementation allowing for arbitrary key and priority types. Multiple identical keys are not permitted, but the priority of existing keys can be changed efficiently.Usage:PriorityQueue{K, V}()     # construct a new priority queue with keys of type K and priorities of type V (forward ordering by default)\nPriorityQueue{K, V}(ord)  # construct a new priority queue with the given types and ordering ord (Base.Order.Forward or Base.Order.Reverse)\nenqueue!(pq, k, v)        # insert the key k into pq with priority v\nenqueue!(pq, k=>v)        # (same, using Pairs)\ndequeue!(pq)              # remove and return the lowest priority key\npeek(pq)                  # return the lowest priority key without removing it\ndelete!(pq, k)            # delete the mapping for the given key in a priority queue, and return the priority queue.PriorityQueue also behaves similarly to a Dict in that keys can be inserted and priorities accessed or changed using indexing notation.Examples:julia> # Julia code\n       pq = PriorityQueue();\n\njulia> # Insert keys with associated priorities\n       pq[\"a\"] = 10; pq[\"b\"] = 5; pq[\"c\"] = 15; pq\nDataStructures.PriorityQueue{Any,Any,Base.Order.ForwardOrdering} with 3 entries:\n  \"c\" => 15\n  \"b\" => 5\n  \"a\" => 10\n\njulia> # Change the priority of an existing key\n       pq[\"a\"] = 0; pq\nDataStructures.PriorityQueue{Any,Any,Base.Order.ForwardOrdering} with 3 entries:\n  \"c\" => 15\n  \"b\" => 5\n  \"a\" => 0"
},

{
    "location": "accumulators.html#",
    "page": "Accumulators and Counters",
    "title": "Accumulators and Counters",
    "category": "page",
    "text": ""
},

{
    "location": "accumulators.html#Accumulators-and-Counters-1",
    "page": "Accumulators and Counters",
    "title": "Accumulators and Counters",
    "category": "section",
    "text": "A accumulator, as defined below, is a data structure that maintains an accumulated number for each key. This is a counter when the accumulated values reflect the counts:struct Accumulator{K, V<:Number}\n    map::Dict{K, V}\nendThere are different ways to construct an accumulator/counter:a = Accumulator{K, V}()  # construct an accumulator with key-type K and\n                         # accumulated value type V\n\na = Accumulator(dict)    # construct an accumulator from a dictionary\n\na = counter(K)           # construct a counter, i.e. an accumulator with\n                         # key type K and value type Int\n\na = counter(dict)        # construct a counter from a dictionary\n\na = counter(seq)         # construct a counter by counting keys in a sequence\n\na = counter(gen)         # construct a counter by counting keys in a generatorUsage of an accumulator/counter:# let a and a2 be accumulators/counters\n\na[x]             # get the current value/count for x.\n                 # if x was not added to a, it returns zero(V)\n\npush!(a, x)      # increment the value/count for x by 1\npush!(a, x, v)   # increment the value/count for x by v\npush!(a, a2)     # add all counts from a2 to a1\n\npop!(a, x)       # remove a key x from a, and return its current value\n\nmerge(a, a2)     # return a new accumulator/counter that combines the\n                 # values/counts in both a and a2"
},

{
    "location": "disjoint_sets.html#",
    "page": "Disjoint Sets",
    "title": "Disjoint Sets",
    "category": "page",
    "text": ""
},

{
    "location": "disjoint_sets.html#Disjoint-Sets-1",
    "page": "Disjoint Sets",
    "title": "Disjoint Sets",
    "category": "section",
    "text": "Some algorithms, such as finding connected components in undirected graph and Kruskal\'s method of finding minimum spanning tree, require a data structure that can efficiently represent a collection of disjoint subsets. A widely used data structure for this purpose is the Disjoint set forest.Usage:a = IntDisjointSets(10)  # creates a forest comprised of 10 singletons\nunion!(a, 3, 5)          # merges the sets that contain 3 and 5 into one and returns the root of the new set\nroot_union!(a, x, y)     # merges the sets that have root x and y into one and returns the root of the new set\nfind_root(a, 3)          # finds the root element of the subset that contains 3\nin_same_set(a, x, y)     # determines whether x and y are in the same set\nelem = push!(a)          # adds a single element in a new set; returns the new element\n                         # (this operation is often called MakeSet)One may also use other element types:a = DisjointSets{AbstractString}([\"a\", \"b\", \"c\", \"d\"])\nunion!(a, \"a\", \"b\")\nin_same_set(a, \"c\", \"d\")\npush!(a, \"f\")Note that the internal implementation of IntDisjointSets is based on vectors, and is very efficient. DisjointSets{T} is a wrapper of IntDisjointSets, which uses a dictionary to map input elements to an internal index. Note for DisjointSets, union!, root_union! and find_root return the index of the root."
},

{
    "location": "heaps.html#",
    "page": "Heaps",
    "title": "Heaps",
    "category": "page",
    "text": ""
},

{
    "location": "heaps.html#Heaps-1",
    "page": "Heaps",
    "title": "Heaps",
    "category": "section",
    "text": "Heaps are data structures that efficiently maintain the minimum (or maximum) for a set of data that may dynamically change.All heaps in this package are derived from AbstractHeap, and provide the following interface:# Let h be a heap, i be a handle, and v be a value.\n\nlength(h)         # returns the number of elements\n\nisempty(h)        # returns whether the heap is empty\n\npush!(h, v)       # add a value to the heap\n\ntop(h)            # return the top value of a heap\n\npop!(h)           # removes the top value, and returns itMutable heaps (values can be changed after being pushed to a heap) are derived from AbstractMutableHeap <: AbstractHeap, and additionally provides the following interface:i = push!(h, v)              # adds a value to the heap and and returns a handle to v\n\nupdate!(h, i, v)             # updates the value of an element (referred to by the handle i)\n\nv, i = top_with_handle(h)    # returns the top value of a heap and its handleCurrently, both min/max versions of binary heap (type BinaryHeap) and mutable binary heap (type MutableBinaryHeap) have been implemented.Examples of constructing a heap:h = binary_minheap(Int)\nh = binary_maxheap(Int)            # create an empty min/max binary heap of integers\n\nh = binary_minheap([1,4,3,2])\nh = binary_maxheap([1,4,3,2])      # create a min/max heap from a vector\n\nh = mutable_binary_minheap(Int)\nh = mutable_binary_maxheap(Int)    # create an empty mutable min/max heap\n\nh = mutable_binary_minheap([1,4,3,2])\nh = mutable_binary_maxheap([1,4,3,2])    # create a mutable min/max heap from a vector"
},

{
    "location": "heaps.html#Functions-using-heaps-1",
    "page": "Heaps",
    "title": "Functions using heaps",
    "category": "section",
    "text": "Heaps can be used to extract the largest or smallest elements of an array without sorting the entire array first:nlargest(3, [0,21,-12,68,-25,14]) # => [68,21,14]\nnsmallest(3, [0,21,-12,68,-25,14]) # => [-25,-12,0]nlargest(n, a) is equivalent to sort(a, lt = >)[1:min(n, end)], and nsmallest(n, a) is equivalent to sort(a, lt = <)[1:min(n, end)]."
},

{
    "location": "ordered_containers.html#",
    "page": "OrderedDicts and OrderedSets",
    "title": "OrderedDicts and OrderedSets",
    "category": "page",
    "text": ""
},

{
    "location": "ordered_containers.html#OrderedDicts-and-OrderedSets-1",
    "page": "OrderedDicts and OrderedSets",
    "title": "OrderedDicts and OrderedSets",
    "category": "section",
    "text": "OrderedDicts are simply dictionaries whose entries have a particular order. For OrderedDicts (and OrderedSets), order refers to insertion order, which allows deterministic iteration over the dictionary or set:d = OrderedDict{Char,Int}()\nfor c in \'a\':\'e\'\n    d[c] = c-\'a\'+1\nend\ncollect(d) # => [(\'a\',1),(\'b\',2),(\'c\',3),(\'d\',4),(\'e\',5)]\n\ns = OrderedSet(π,e,γ,catalan,φ)\ncollect(s) # => [π = 3.1415926535897...,\n           #     e = 2.7182818284590...,\n           #     γ = 0.5772156649015...,\n           #     catalan = 0.9159655941772...,\n           #     φ = 1.6180339887498...]All standard Dict functions are available for OrderedDicts, and all Set operations are available for OrderedSets.Note that to create an OrderedSet of a particular type, you must specify the type in curly-braces:# create an OrderedSet of Strings\nstrs = OrderedSet{AbstractString}()"
},

{
    "location": "default_dict.html#",
    "page": "DefaultDict and DefaultOrderedDict",
    "title": "DefaultDict and DefaultOrderedDict",
    "category": "page",
    "text": ""
},

{
    "location": "default_dict.html#DefaultDict-and-DefaultOrderedDict-1",
    "page": "DefaultDict and DefaultOrderedDict",
    "title": "DefaultDict and DefaultOrderedDict",
    "category": "section",
    "text": "A DefaultDict allows specification of a default value to return when a requested key is not in a dictionary.While the implementation is slightly different, a DefaultDict can be thought to provide a normal Dict with a default value. A DefaultOrderedDict does the same for an OrderedDict.Constructors:DefaultDict(default, kv)    # create a DefaultDict with a default value or function,\n                            # optionally wrapping an existing dictionary\n                            # or array of key-value pairs\n\nDefaultDict{KeyType, ValueType}(default)   # create a DefaultDict with Dict type (KeyType,ValueType)\n\nDefaultOrderedDict(default, kv)     # create a DefaultOrderedDict with a default value or function,\n                                    # optionally wrapping an existing dictionary\n                                    # or array of key-value pairs\n\nDefaultOrderedDict{KeyType, ValueType}(default) # create a DefaultOrderedDict with Dict type (KeyType,ValueType)All constructors also take a passkey::Bool=false keyword argument which determines whether to pass along the key argument when calling the default function. It has no effect when the key is just a value.Examples using DefaultDict:using DataStructuresdd = DefaultDict(1)               # create an (Any=>Any) DefaultDict with a default value of 1dd = DefaultDict{AbstractString, Int}(0)  # create a (AbstractString=>Int) DefaultDict with a default value of 0d = Dict(\'a\'=>1, \'b\'=>2)\ndd = DefaultDict(0, d)            # provide a default value to an existing dictionary\nd[\'c\']  # should raise a KeyError because \'c\' key doesn\'t exist\ndd[\'c\']dd = DefaultOrderedDict(time)     # call time() to provide the default value for an OrderedDict\ndd = DefaultDict(Dict)            # Create a dictionary of dictionaries - Dict() is called to provide the default value\ndd = DefaultDict(()->myfunc())    # call function myfunc to provide the default valueThese all create the same default dictdd = DefaultDict{AbstractString, Vector{Int}}(() -> Vector{Int}())dd = DefaultDict{AbstractString, Vector{Int}}(() -> Int[])dd = DefaultDict{AbstractString, Vector{Int}}(Vector{Int})\n\npush!(dd[\"A\"], 1)\n\npush!(dd[\"B\"], 2)\n\nddCreate a Dictionary of type AbstractString=>DefaultDict{AbstractString, Int}, where the default of the inner set of DefaultDicts is zerodd = DefaultDict{AbstractString, DefaultDict}(() -> DefaultDict{AbstractString,Int}(0))Use DefaultDict to cache an expensive function call, i.e., memoizedd = DefaultDict{AbstractString, Int}(passkey=true) do key\n    len = length(key)\n    sleep(len)\n    return len\nend\n\ndd[\"hi\"]  # slow\n\ndd[\"ho\"]  # slow\n\ndd[\"hi\"]  # fastNote that in the second-last example, we need to use a function to create each new DefaultDict. If we forget, we will end up using the sameDefaultDict for all default values:dd = DefaultDict{AbstractString, DefaultDict}(DefaultDict{AbstractString,Int}(0));\ndd[\"a\"]\ndd[\"b\"][\"a\"] = 1\ndd[\"a\"]"
},

{
    "location": "trie.html#",
    "page": "Trie",
    "title": "Trie",
    "category": "page",
    "text": ""
},

{
    "location": "trie.html#Trie-1",
    "page": "Trie",
    "title": "Trie",
    "category": "section",
    "text": "An implementation of the Trie data structure. This is an associative structure, with AbstractString keys:t = Trie{Int}()\nt[\"Rob\"] = 42\nt[\"Roger\"] = 24\nhaskey(t, \"Rob\")  # true\nget(t, \"Rob\", nothing)  # 42\nkeys(t)  # \"Rob\", \"Roger\"\nkeys(subtrie(t, \"Ro\"))  # \"b\", \"ger\"Constructors:Trie(keys, values)                  # construct a Trie with the given keys and values\nTrie(keys)                          # construct a Trie{Void} with the given keys and with values = nothing\nTrie(kvs::AbstractVector{(K, V)})   # construct a Trie from the given vector of (key, value) pairs\nTrie(kvs::AbstractDict{K, V})       # construct a Trie from the given associative structureThis package also provides an iterator path(t::Trie, str) for looping over all the nodes encountered in searching for the given string str. This obviates much of the boilerplate code needed in writing many trie algorithms. For example, to test whether a trie contains any prefix of a given string, use:seen_prefix(t::Trie, str) = any(v -> v.is_key, path(t, str))"
},

{
    "location": "linked_list.html#",
    "page": "Linked List",
    "title": "Linked List",
    "category": "page",
    "text": ""
},

{
    "location": "linked_list.html#Linked-List-1",
    "page": "Linked List",
    "title": "Linked List",
    "category": "section",
    "text": "A list of sequentially linked nodes. This allows efficient insertion of nodes to the front of the list:julia> l1 = nil()\nnil()\n\njulia> l2 = cons(1, l1)\nlist(1)\n\njulia> l3 = list(2, 3)\nlist(2, 3)\n\njulia> l4 = cat(l1, l2, l3)\nlist(1, 2, 3)\n\njulia> l5 = map((x) -> x*2, l4)\nlist(2, 4, 6)\n\njulia> for i in l5; print(i); end\n246"
},

{
    "location": "intset.html#",
    "page": "DataStructures.IntSet",
    "title": "DataStructures.IntSet",
    "category": "page",
    "text": ""
},

{
    "location": "intset.html#DataStructures.IntSet-1",
    "page": "DataStructures.IntSet",
    "title": "DataStructures.IntSet",
    "category": "section",
    "text": "DataStructures.IntSet is a drop-in replacement for the Base IntSet type. It efficiently stores dense collections of small non-negative Ints as a sorted set. The constructor IntSet([itr]) constructs a sorted set of the integers generated by the given iterable object, or an empty set if no argument is given. If the set will be sparse (for example holding a few very large integers), use Set or SortedSet instead.A complement IntSet may be constructed with complement or complement!. The complement of an empty IntSet contains typemax(Int) elements from 0 to typemax(Int)-1."
},

{
    "location": "sorted_containers.html#",
    "page": "Sorted Containers",
    "title": "Sorted Containers",
    "category": "page",
    "text": ""
},

{
    "location": "sorted_containers.html#Sorted-Containers-1",
    "page": "Sorted Containers",
    "title": "Sorted Containers",
    "category": "section",
    "text": "CurrentModule = DataStructuresThree sorted containers are provided: SortedDict, SortedMultiDict and SortedSet. SortedDict is similar to the built-in Julia type Dict with the additional feature that the keys are stored in sorted order and can be efficiently iterated in this order. SortedDict is a subtype of AbstractDict. It is generally slower than Dict because looking up a key requires an O(log n) tree search rather than an expected O(1) hash-table lookup time as with Dict. SortedDict is a parametrized type with three parameters, the key type K, the value type V, and the ordering type O. SortedSet has only keys; it is an alternative to the built-in Set container. Internally, SortedSet is implemented as a SortedDict in which the value type is Void. Finally, SortedMultiDict is similar to SortedDict except that each key can be associated with multiple values. The key=>value pairs in a SortedMultiDict are stored according to the sorted order for keys, and key=>value pairs with the same key are stored in order of insertion.The containers internally use a 2-3 tree, which is a kind of balanced tree and is described in many elementary data structure textbooks.The containers require two functions to compare keys: a less-than and equals function. With the default ordering argument, the comparison functions are isless(key1,key2) (true when key1 < key2) and isequal(key1,key2) (true when key1 == key2) where key1 and key2 are keys. More details are provided below."
},

{
    "location": "sorted_containers.html#Tokens-for-Sorted-Containers-1",
    "page": "Sorted Containers",
    "title": "Tokens for Sorted Containers",
    "category": "section",
    "text": "The sorted container objects use a special type for indexing called a token defined as a two-entry tuple and aliased as SDToken, SMDToken, and SetToken for SortedDict, SortedMultiDict and SortedSet respectively. A token is the address of a single data item in the container and can be dereferenced in time O(1).The first entry of a Token tuple is the container as a whole, and the second refers to the particular item. The second part is called a semitoken. The types for a semitoken are SDSemiToken, SMDSemiToken, and SetSemiToken for the three types of containers SortedDict, SortedMultiDict and SortedSet. These types are all aliases of IntSemiToken.A restriction for the sorted containers is that IntSemiToken or its aliases cannot used as the key-type. This is because ambiguity would result between the two subscripting calls sc[k] and sc[st] described below. In the rare scenario that a sorted container whose key-type is IntSemiToken is required, a workaround is to wrap the key inside another immutable structure.In the current version of Julia, it is costly to operate on tuples whose entries are not bits-types because such tuples are allocated on the heap. For example, the first entry of a token is a pointer to a container (a non-bits type), so a new token is allocated on the heap rather than the stack. In order to avoid performance loss, the package uses tokens less frequently than semitokens. For a function taking a token as an argument like deref described below, if it is invoked by explicitly naming the token like this:tok = (sc,st)   # sc is a sorted container, st is a semitoken\nk,v = deref(tok)then there may be a loss of performance compared to:k,v = deref((sc,st))because the former needs an extra heap allocation step for tok.The notion of token is similar to the concept of iterators used by C++ standard containers. Tokens can be explicitly advanced or regressed through the data in the sorted order; they are implicitly advanced or regressed via iteration loops defined below.A token may take two special values: the before-start value and the past-end value. These values act as lower and upper bounds on the actual data. The before-start token can be advanced, while the past-end token can be regressed. A dereferencing operation on either leads to an error.In the current implementation, semitokens are internally stored as integers. However, for the purpose of future compatibility, the user should not extract this internal representation; these integers do not have a documented interpretation in terms of the container."
},

{
    "location": "sorted_containers.html#Constructors-for-Sorted-Containers-1",
    "page": "Sorted Containers",
    "title": "Constructors for Sorted Containers",
    "category": "section",
    "text": ""
},

{
    "location": "sorted_containers.html#DataStructures.SortedDict-Union{Tuple{Ord}, Tuple{Ord}} where Ord<:Base.Order.Ordering",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedDict",
    "category": "method",
    "text": "SortedDict(o=Forward)\n\nConstruct an empty SortedDict with key type K and value type V. If K and V are not specified, the dictionary defaults to a SortedDict{Any,Any}. Keys and values are converted to the given type upon insertion. Ordering o defaults to Forward ordering.\n\nNote that a key type of Any or any other abstract type will lead to slow performance, as the values are stored boxed (i.e., as pointers), and insertion will require a run-time lookup of the appropriate comparison function. It is recommended to always specify a concrete key type, or to use one of the constructors below in which the key type is inferred.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedDict-Union{Tuple{Ord}, Tuple{Ord}, Tuple{D}, Tuple{K}} where Ord<:Base.Order.Ordering where D where K",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedDict",
    "category": "method",
    "text": "SortedDict(iter, o=Forward)\n\nand SortedDict{K,V}(iter, o=Forward)\n\nConstruct a SortedDict from an arbitrary iterable object of key=>value pairs. If K and V are not specified, the key type and value type are inferred from the given iterable. The ordering object o defaults to Forward.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedDict-Tuple{Vararg{Pair,N} where N}",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedDict",
    "category": "method",
    "text": "SortedDict(k1=>v1, k2=>v2, ...)\n\nand SortedDict{K,V}(k1=>v1, k2=>v2, ...)\n\nConstruct a SortedDict from the given key-value pairs. If K and V are not specified, key type and value type are inferred from the given key-value pairs, and ordering is assumed to be Forward ordering.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedDict-Union{Tuple{Ord}, Tuple{D}, Tuple{K}, Tuple{Ord,Vararg{Pair,N} where N}} where Ord<:Base.Order.Ordering where D where K",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedDict",
    "category": "method",
    "text": "SortedDict{K,V}(o, k1=>v1, k2=>v2, ...)\n\nConstruct a SortedDict from the given pairs with the specified ordering o. If K and V are not specified, the key type and value type are inferred from the given pairs. See below for more information about ordering.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#SortedDict-constructors-1",
    "page": "Sorted Containers",
    "title": "SortedDict constructors",
    "category": "section",
    "text": "SortedDict(o::Ord) where {Ord <: Ordering}SortedDict{K,V}(o=Forward)Construct an empty SortedDict with key type K and value type V with o ordering (default to forward ordering).SortedDict{K,D,Ord}(o::Ord) where {K, D, Ord <: Ordering}SortedDict(ps::Pair...)SortedDict{K,D}(o::Ord, ps::Pair...) where {K,D,Ord<:Ordering}"
},

{
    "location": "sorted_containers.html#DataStructures.SortedMultiDict-Union{Tuple{Ord}, Tuple{Ord}, Tuple{D}, Tuple{K}} where Ord where D where K",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedMultiDict",
    "category": "method",
    "text": "SortedMultiDict{K,D}(iter)\n\nTakes an arbitrary iterable object of key=>value pairs with key type K and value type D. The default Forward ordering is used.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedMultiDict-Tuple{}",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedMultiDict",
    "category": "method",
    "text": "SortedMultiDict()\n\nConstruct an empty SortedMultiDict with key type Any and value type Any. Ordering defaults to Forward ordering.\n\nNote that a key type of Any or any other abstract type will lead to slow performance.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedMultiDict-Union{Tuple{O}, Tuple{O}} where O<:Base.Order.Ordering",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedMultiDict",
    "category": "method",
    "text": "SortedMultiDict(o)\n\nConstruct an empty SortedMultiDict with key type Any and value type Any, ordered using o.\n\nNote that a key type of Any or any other abstract type will lead to slow performance.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedMultiDict-Tuple{Vararg{Pair,N} where N}",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedMultiDict",
    "category": "method",
    "text": "SortedMultiDict(k1=>v1, k2=>v2, ...)\n\nArguments are key-value pairs for insertion into the multidict. The keys must be of the same type as one another; the values must also be of one type.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedMultiDict-Tuple{Base.Order.Ordering,Vararg{Pair,N} where N}",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedMultiDict",
    "category": "method",
    "text": "SortedMultiDict(o, k1=>v1, k2=>v2, ...)\n\nThe first argument o is an ordering object. The remaining arguments are key-value pairs for insertion into the multidict. The keys must be of the same type as one another; the values must also be of one type.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedMultiDict-Union{Tuple{Any}, Tuple{D}, Tuple{K}} where D where K",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedMultiDict",
    "category": "method",
    "text": "SortedMultiDict{K,D}(iter)\n\nTakes an arbitrary iterable object of key=>value pairs with key type K and value type D. The default Forward ordering is used.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedMultiDict-Union{Tuple{Ord}, Tuple{D}, Tuple{K}, Tuple{Ord,Any}} where Ord<:Base.Order.Ordering where D where K",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedMultiDict",
    "category": "method",
    "text": "SortedMultiDict{K,D}(o, iter)\n\nTakes an arbitrary iterable object of key=>value pairs with key type K and value type D. The ordering object o is explicitly given.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#SortedMultiDict-constructors-1",
    "page": "Sorted Containers",
    "title": "SortedMultiDict constructors",
    "category": "section",
    "text": "SortedMultiDict(ks, vs, o)Construct a SortedMultiDict using keys given by ks, values given by vs and ordering object o. The ordering object defaults to Forward if not specified. The two arguments ks and vs are 1-dimensional arrays of the same length in which ks holds keys and vs holds the corresponding values.SortedMultiDict{K,D,Ord}(o::Ord) where {K,D,Ord}SortedMultiDict()SortedMultiDict(o::O) where {O<:Ordering}SortedMultiDict(ps::Pair...)SortedMultiDict(o::Ordering, ps::Pair...)SortedMultiDict{K,D}(kv) where {K,D}SortedMultiDict{K,D}(o::Ord, kv) where {K,D,Ord<:Ordering}"
},

{
    "location": "sorted_containers.html#DataStructures.SortedSet",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedSet",
    "category": "type",
    "text": "SortedSet(iter, o=Forward)\n\nand     SortedSet{K}(iter, o=Forward) and     SortedSet(o, iter) and     SortedSet{K}(o, iter)\n\nConstruct a SortedSet using keys given by iterable iter (e.g., an array) and ordering object o. The ordering object defaults to Forward if not specified.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedSet-Tuple{}",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedSet",
    "category": "method",
    "text": "SortedSet()\n\nConstruct a SortedSet{Any} with Forward ordering.\n\nNote that a key type of Any or any other abstract type will lead to slow performance.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedSet-Union{Tuple{O}, Tuple{O}} where O<:Base.Order.Ordering",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedSet",
    "category": "method",
    "text": "SortedSet(o)\n\nConstruct a SortedSet{Any} with o ordering.\n\nNote that a key type of Any or any other abstract type will lead to slow performance.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedSet-Union{Tuple{}, Tuple{K}} where K",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedSet",
    "category": "method",
    "text": "SortedSet{K}()\n\nConstruct a SortedSet of keys of type K with Forward ordering.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.SortedSet-Union{Tuple{O}, Tuple{O}, Tuple{K}} where O<:Base.Order.Ordering where K",
    "page": "Sorted Containers",
    "title": "DataStructures.SortedSet",
    "category": "method",
    "text": "SortedSet{K}(o)\n\nConstruct a SortedSet of keys of type K with ordering given according  o parameter.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#SortedSets-constructors-1",
    "page": "Sorted Containers",
    "title": "SortedSets constructors",
    "category": "section",
    "text": "SortedSet{K, Ord <: Ordering}SortedSet()SortedSet(o::O) where {O<:Ordering}SortedSet{K}() where {K}SortedSet{K}(o::O) where {K,O<:Ordering}"
},

{
    "location": "sorted_containers.html#Complexity-of-Sorted-Containers-1",
    "page": "Sorted Containers",
    "title": "Complexity of Sorted Containers",
    "category": "section",
    "text": "In the list of functions below, the running time of the various operations is provided. In these running times, n denotes the current size (number of items) in the container at the time of the function call, and c denotes the time needed to compare two keys."
},

{
    "location": "sorted_containers.html#Base.getindex-Tuple{SortedDict,Any}",
    "page": "Sorted Containers",
    "title": "Base.getindex",
    "category": "method",
    "text": "v = sd[k]\n\nArgument sd is a SortedDict and k is a key. In an expression, this retrieves the value (v) associated with the key (or KeyError if none). On the left-hand side of an assignment, this assigns or reassigns the value associated with the key. (For assigning and reassigning, see also insert! below.) Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.first-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "Base.first",
    "category": "method",
    "text": "first(sc)\n\nArgument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the first item (a k=>v pair for SortedDict and SortedMultiDict or a key for SortedSet) according to the sorted order in the container. Thus, first(sc) is equivalent to deref((sc,startof(sc))). It is an error to call this function on an empty container. Time: O(log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.first-Tuple{SortedMultiDict}",
    "page": "Sorted Containers",
    "title": "Base.first",
    "category": "method",
    "text": "first(sc)\n\nArgument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the first item (a k=>v pair for SortedDict and SortedMultiDict or a key for SortedSet) according to the sorted order in the container. Thus, first(sc) is equivalent to deref((sc,startof(sc))). It is an error to call this function on an empty container. Time: O(log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.first-Tuple{SortedSet}",
    "page": "Sorted Containers",
    "title": "Base.first",
    "category": "method",
    "text": "first(sc)\n\nArgument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the first item (a k=>v pair for SortedDict and SortedMultiDict or a key for SortedSet) according to the sorted order in the container. Thus, first(sc) is equivalent to deref((sc,startof(sc))). It is an error to call this function on an empty container. Time: O(log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.last-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "Base.last",
    "category": "method",
    "text": "last(sc)\n\nArgument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the last item (a k=>v pair for SortedDict and SortedMultiDict or a key for SortedSet) according to the sorted order in the container. Thus, last(sc) is equivalent to deref((sc,lastindex(sc))). It is an error to call this function on an empty container. Time: O(log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.last-Tuple{SortedMultiDict}",
    "page": "Sorted Containers",
    "title": "Base.last",
    "category": "method",
    "text": "last(sc)\n\nArgument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the last item (a k=>v pair for SortedDict and SortedMultiDict or a key for SortedSet) according to the sorted order in the container. Thus, last(sc) is equivalent to deref((sc,lastindex(sc))). It is an error to call this function on an empty container. Time: O(log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.last-Tuple{SortedSet}",
    "page": "Sorted Containers",
    "title": "Base.last",
    "category": "method",
    "text": "last(sc)\n\nArgument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the last item (a k=>v pair for SortedDict and SortedMultiDict or a key for SortedSet) according to the sorted order in the container. Thus, last(sc) is equivalent to deref((sc,lastindex(sc))). It is an error to call this function on an empty container. Time: O(log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Navigating-the-Containers-1",
    "page": "Sorted Containers",
    "title": "Navigating the Containers",
    "category": "section",
    "text": "getindex(m::SortedDict, k_)find(m::SortedDict, k_)deref((sc, st))Argument (sc,st) is a token (i.e., sc is a container and st is a semitoken). Note the double-parentheses in the calling syntax: the argument of deref is a token, which is defined to be a 2-tuple. This returns a key=>value pair. pointed to by the token for SortedDict and SortedMultiDict. Note that the syntax k,v=deref((sc,st)) is valid because Julia automatically iterates over the two entries of the Pair in order to assign k and v. For SortedSet this returns a key. Time: O(1)deref_key((sc, st))Argument (sc,st) is a token for SortedMultiDict or SortedDict. This returns the key (i.e., the first half of a key=>value pair) pointed to by the token. This functionality is available as plain deref for SortedSet. Time: O(1)deref_value((sc, st))Argument (sc,st) is a token for SortedMultiDict or SortedDict. This returns the value (i.e., the second half of a key=>value pair) pointed to by the token. Time: O(1)startof(sc)Argument sc is SortedDict, SortedMultiDict or SortedSet. This function returns the semitoken of the first item according to the sorted order in the container. If the container is empty, it returns the past-end semitoken. Time: O(log n)endof(sc)Argument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the semitoken of the last item according to the sorted order in the container. If the container is empty, it returns the before-start semitoken. Time: O(log n)first(sc::SortedDict)first(sc::SortedMultiDict)first(sc::SortedSet)last(sc::SortedDict)last(sc::SortedMultiDict)last(sc::SortedSet)pastendsemitoken(sc)Argument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the past-end semitoken. Time: O(1)beforestartsemitoken(sc)Argument sc is a SortedDict, SortedMultiDict or SortedSet. This function returns the before-start semitoken. Time: O(1)advance((sc,st))Argument (sc,st) is a token. This function returns the semitoken of the next entry in the container according to the sort order of the keys. After the last item, this routine returns the past-end semitoken. It is an error to invoke this function if (sc,st) is the past-end token. If (sc,st) is the before-start token, then this routine returns the semitoken of the first item in the sort order (i.e., the same semitoken returned by the startof function). Time: O(log n)regress((sc,st))Argument (sc,st) is a token. This function returns the semitoken of the previous entry in the container according to the sort order of the keys. If (sc,st) indexes the first item, this routine returns the before-start semitoken. It is an error to invoke this function if (sc,st) is the before-start token. If (sc,st) is the past-end token, then this routine returns the smitoken of the last item in the sort order (i.e., the same semitoken returned by the endof function). Time: O(log n)searchsortedfirst(sc,k)Argument sc is a SortedDict, SortedMultiDict or SortedSet and k is a key. This routine returns the semitoken of the first item in the container whose key is greater than or equal to k. If there is no such key, then the past-end semitoken is returned. Time: O(c log n)searchsortedlast(sc,k)Argument sc is a SortedDict, SortedMultiDict or SortedSet and k is a key. This routine returns the semitoken of the last item in the container whose key is less than or equal to k. If there is no such key, then the before-start semitoken is returned. Time: O(c log n)searchsortedafter(sc,k)Argument sc is a SortedDict, SortedMultiDict or SortedSet and k is an element of the key type. This routine returns the semitoken of the first item in the container whose key is greater than k. If there is no such key, then the past-end semitoken is returned. Time: O(c log n)searchequalrange(sc,k)Argument sc is a SortedMultiDict and k is an element of the key type. This routine returns a pair of semitokens; the first of the pair is the semitoken addressing the first item in the container with key k and the second is the semitoken addressing the last item in the container with key k. If no item matches the given key, then the pair (past-end-semitoken, before-start-semitoken) is returned. Time: O(c log n)"
},

{
    "location": "sorted_containers.html#Base.insert!-Tuple{SortedDict,Any,Any}",
    "page": "Sorted Containers",
    "title": "Base.insert!",
    "category": "method",
    "text": "insert!(sc, k)\n\nArgument sc is a SortedDict or SortedMultiDict, k is a key and v is the corresponding value. This inserts the (k,v) pair into the container. If the key is already present in a SortedDict, this overwrites the old value. In the case of SortedMultiDict, no overwriting takes place (since SortedMultiDict allows the same key to associate with multiple values). In the case of SortedDict, the return value is a pair whose first entry is boolean and indicates whether the insertion was new (i.e., the key was not previously present) and the second entry is the semitoken of the new entry. In the case of SortedMultiDict, a semitoken is returned (but no boolean). Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.insert!-Tuple{SortedMultiDict,Any,Any}",
    "page": "Sorted Containers",
    "title": "Base.insert!",
    "category": "method",
    "text": "insert!(sc, k)\n\nArgument sc is a SortedDict or SortedMultiDict, k is a key and v is the corresponding value. This inserts the (k,v) pair into the container. If the key is already present in a SortedDict, this overwrites the old value. In the case of SortedMultiDict, no overwriting takes place (since SortedMultiDict allows the same key to associate with multiple values). In the case of SortedDict, the return value is a pair whose first entry is boolean and indicates whether the insertion was new (i.e., the key was not previously present) and the second entry is the semitoken of the new entry. In the case of SortedMultiDict, a semitoken is returned (but no boolean). Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.insert!-Tuple{SortedSet,Any}",
    "page": "Sorted Containers",
    "title": "Base.insert!",
    "category": "method",
    "text": "insert!(sc, k)\n\nArgument sc is a SortedSet and k is a key. This inserts the key into the container. If the key is already present, this overwrites the old value. (This is not necessarily a no-op; see below for remarks about the customizing the sort order.) The return value is a pair whose first entry is boolean and indicates whether the insertion was new (i.e., the key was not previously present) and the second entry is the semitoken of the new entry. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.push!-Tuple{SortedSet,Any}",
    "page": "Sorted Containers",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(sc, k)\n\nArgument sc is a SortedSet and k is a key. This inserts the key into the container. If the key is already present, this overwrites the old value. (This is not necessarily a no-op; see below for remarks about the customizing the sort order.) The return value is sc. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.push!-Tuple{SortedDict,Pair}",
    "page": "Sorted Containers",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(sc, k=>v)\n\nArgument sc is a SortedDict or SortedMultiDict and k=>v is a key-value pair. This inserts the key-value pair into the container. If the key is already present, this overwrites the old value. The return value is sc. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.push!-Tuple{SortedMultiDict,Pair}",
    "page": "Sorted Containers",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(sc, k=>v)\n\nArgument sc is a SortedDict or SortedMultiDict and k=>v is a key-value pair. This inserts the key-value pair into the container. If the key is already present, this overwrites the old value. The return value is sc. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.pop!-Tuple{SortedDict,Any}",
    "page": "Sorted Containers",
    "title": "Base.pop!",
    "category": "method",
    "text": "pop!(sc, k)\n\nDeletes the item with key k in SortedDict or SortedSet sc and returns the value that was associated with k in the case of SortedDict or k itself in the case of SortedSet. A KeyError results if k is not in sc. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.pop!-Tuple{SortedSet,Any}",
    "page": "Sorted Containers",
    "title": "Base.pop!",
    "category": "method",
    "text": "pop!(sc, k)\n\nDeletes the item with key k in SortedDict or SortedSet sc and returns the value that was associated with k in the case of SortedDict or k itself in the case of SortedSet. A KeyError results if k is not in sc. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.pop!-Tuple{SortedSet}",
    "page": "Sorted Containers",
    "title": "Base.pop!",
    "category": "method",
    "text": "pop!(ss)\n\nDeletes the item with first key in SortedSet ss and returns the key. A BoundsError results if ss is empty. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.setindex!-Tuple{SortedDict,Any,Any}",
    "page": "Sorted Containers",
    "title": "Base.setindex!",
    "category": "method",
    "text": "sc[st] = v\n\nIf st is a semitoken and sc is a SortedDict or SortedMultiDict, then sc[st] refers to the value field of the (key,value) pair that the full token (sc,st) refers to. This expression may occur on either side of an assignment statement. Time: O(1)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Inserting-and-Deleting-in-Sorted-Containers-1",
    "page": "Sorted Containers",
    "title": "Inserting & Deleting in Sorted Containers",
    "category": "section",
    "text": "empty!(sc)Argument sc is a SortedDict, SortedMultiDict or SortedSet. This empties the container. Time: O(1).insert!(sc::SortedDict, k, v)insert!(sc::SortedMultiDict, k, v)insert!(sc::SortedSet, k)push!(sc::SortedSet, k)push!(sc::SortedDict, pr::Pair)push!(sc::SortedMultiDict, pr::Pair)delete!((sc, st))Argument (sc,st) is a token for a SortedDict, SortedMultiDict or SortedSet. This operation deletes the item addressed by (sc,st). It is an error to call this on an entry that has already been deleted or on the before-start or past-end tokens. After this operation is complete, (sc,st) is an invalid token and cannot be used in any further operations. Time: O(log n)pop!(sc::SortedDict, k)pop!(ss::SortedSet, k)pop!(ss::SortedSet)setindex!(m::SortedDict, d_, k_)"
},

{
    "location": "sorted_containers.html#Token-Manipulation-1",
    "page": "Sorted Containers",
    "title": "Token Manipulation",
    "category": "section",
    "text": "compare(sc, st1, st2)Here, st1 and st2 are semitokens for the same container sc; this function determines the relative positions of the data items indexed by (sc,st1) and (sc,st2) in the sorted order. The return value is -1 if (sc,st1) precedes (sc,st2), 0 if they are equal, and 1 if (sc,st1) succeeds (sc,st2). This function compares the tokens by determining their relative position within the tree without dereferencing them. For SortedDict it is mostly equivalent to comparing deref_key((sc,st1)) to deref_key((sc,st2)) using the ordering of the SortedDict except in the case that either (sc,st1) or (sc,st2) is the before-start or past-end token, in which case the deref operation will fail. Which one is more efficient depends on the time-complexity of comparing two keys. Similarly, for SortedSet it is mostly equivalent to comparing deref((sc,st1)) to deref((sc,st2)). For SortedMultiDict, this function is not equivalent to a key comparison since two items in a SortedMultiDict with the same key are not necessarily the same item. Time: O(log n)status((sc, st))This function returns 0 if the token (sc,st) is invalid (e.g., refers to a deleted item), 1 if the token is valid and points to data, 2 if the token is the before-start token and 3 if it is the past-end token. Time: O(1)"
},

{
    "location": "sorted_containers.html#Iteration-Over-Sorted-Containers-1",
    "page": "Sorted Containers",
    "title": "Iteration Over Sorted Containers",
    "category": "section",
    "text": "As is standard in Julia, iteration over the containers is implemented via calls to the iterate function. It is usual practice, however, to call these functions implicitly with a for-loop rather than explicitly, so they are presented here in for-loop notation. Internally, all of these iterations are implemented with semitokens that are advanced via the advance operation. Each iteration of these loops requires O(log n) operations to advance the semitoken. If one loops over an entire container, then the amortized cost of advancing the semitoken drops to O(1).The following snippet loops over the entire container sc, where sc is a SortedDict or SortedMultiDict:for (k,v) in sc\n   < body >\nendIn this loop, (k,v) takes on successive (key,value) pairs according to the sort order of the key. If one uses:for p in sc\n   < body >\nendwhere sc is a SortedDict or SortedMultiDict, then p is a k=>v pair.For SortedSet one uses:for k in ss\n   < body >\nendThere are two ways to iterate over a subrange of a container. The first is the inclusive iteration for SortedDict and SortedMultiDict:for (k,v) in inclusive(sc,st1,st2)\n  < body >\nendHere, st1 and st2 are semitokens that refer to the container sc. It is acceptable for (sc,st1) to be the past-end token or (sc,st2) to be the before-start token (in these cases, the body is not executed). If compare(sc,st1,st2)==1 then the body is not executed. A second calling format for inclusive is inclusive(sc,(st1,st2)). One purpose for second format is so that the return value of searchequalrange may be used directly as the second argument to inclusive.One can also define a loop that excludes the final item:for (k,v) in exclusive(sc,st1,st2)\n  < body >\nendIn this case, all the data addressed by tokens from (sc,st1) up to but excluding (sc,st2) are executed. The body is not executed at all if compare(sc,st1,st2)>=0. In this setting, either or both can be the past-end token, and (sc,st2) can be the before-start token. For the sake of consistency, exclusive also supports the calling format exclusive(sc,(st1,st2)). In the previous few snippets, if the loop object is p instead of (k,v), then p is a k=>v pair.Both the inclusive and exclusive functions return objects that can be saved and used later for iteration. The validity of the tokens is not checked until the loop initiates.For SortedSet the usage is:for k in inclusive(ss,st1,st2)\n  < body >\nend\n\nfor k in exclusive(ss,st1,st2)\n  < body >\nendIf sc is a SortedDict or SortedMultiDict, one can iterate over just keys or just values:for k in keys(sc)\n   < body >\nend\n\nfor v in values(sc)\n   < body >\nendFinally, one can retrieve semitokens during any of these iterations. In the case of SortedDict and SortedMultiDict, one uses:for (st,k,v) in semitokens(sc)\n    < body >\nend\n\nfor (st,k) in semitokens(keys(sc))\n    < body >\nend\n\nfor (st,v) in semitokens(values(sc))\n    < body >\nendIn each of the above three iterations, st is a semitoken referring to the current (k,v) pair. In the case of SortedSet, the following iteration may be used:for (st,k) in semitokens(ss)\n    < body >\nendIf one wishes to retrieve only semitokens, the following may be used:for st in onlysemitokens(sc)\n    < body >\nendIn this case, sc is a SortedDict, SortedMultiDict, or SortedSet. To be compatible with standard containers, the package also offers eachindex iteration:for ind in eachindex(sc)\n    < body >\nendThis iteration function eachindex is equivalent to keys in the case of SortedDict. It is equivalent to onlysemitokens in the case of SortedMultiDict and SortedSet.In place of sc in the above keys, values and semitokens, snippets, one could also use inclusive(sc,st1,st2) or exclusive(sc,st1,st2). Similarly, for SortedSet, one can iterate over semitokens(inclusive(ss,st1,st2)) or semitokens(exclusive(ss,st1,st2))Note that it is acceptable for the loop body in the above semitokens code snippets to invoke delete!((sc,st)) or delete!((ss,st)). This is because the for-loop internal state variable is already advanced to the next token at the beginning of the body, so st is not necessarily referred to in the loop body (unless the user refers to it)."
},

{
    "location": "sorted_containers.html#Base.eltype-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "Base.eltype",
    "category": "method",
    "text": "eltype(sc)\n\nReturns the (key,value) type (a 2-entry pair, i.e., Pair{K,V}) for SortedDict and SortedMultiDict. Returns the key type for SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\neltype(sc)\n\nReturns the (key,value) type (a 2-entry pair, i.e., Pair{K,V}) for SortedDict and SortedMultiDict. Returns the key type for SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\neltype(sc)\n\nReturns the key type for SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.keytype-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "Base.keytype",
    "category": "method",
    "text": "keytype(sc)\n\nReturns the key type for SortedDict, SortedMultiDict and SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\nkeytype(sc)\n\nReturns the key type for SortedDict, SortedMultiDict and SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\nkeytype(sc)\n\nReturns the key type for SortedDict, SortedMultiDict and SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.valtype-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "Base.valtype",
    "category": "method",
    "text": "valtype(sc)\n\nReturns the value type for SortedDict and SortedMultiDict. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\nvaltype(sc)\n\nReturns the value type for SortedDict and SortedMultiDict. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.ordtype-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "DataStructures.ordtype",
    "category": "method",
    "text": "ordtype(sc)\n\nReturns the order type for SortedDict, SortedMultiDict and SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\nordtype(sc)\n\nReturns the order type for SortedDict, SortedMultiDict and SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\nordtype(sc)\n\nReturns the order type for SortedDict, SortedMultiDict and SortedSet. This function may also be applied to the type itself. Time: O(1)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.orderobject-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "DataStructures.orderobject",
    "category": "method",
    "text": "orderobject(sc)\n\nReturns the order object used to construct the container. Time: O(1)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.haskey-Tuple{SortedDict,Any}",
    "page": "Sorted Containers",
    "title": "Base.haskey",
    "category": "method",
    "text": "haskey(sc,k)\n\nReturns true if key k is present for SortedDict, SortedMultiDict or SortedSet sc. For SortedSet, haskey(sc,k) is a synonym for in(k,sc). For SortedDict and SortedMultiDict, haskey(sc,k) is equivalent to in(k,keys(sc)). Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.getkey-Tuple{SortedDict,Any,Any}",
    "page": "Sorted Containers",
    "title": "Base.getkey",
    "category": "method",
    "text": "getkey(sd,k,defaultk)\n\nReturns key k where sd is a SortedDict, if k is in sd else it returns defaultk. If the container uses in its ordering an eq method different from isequal (e.g., case-insensitive ASCII strings illustrated below), then the return value is the actual key stored in the SortedDict that is equivalent to k according to the eq method, which might not be equal to k. Similarly, if the user performs an implicit conversion as part of the call (e.g., the container has keys that are floats, but the k argument to getkey is an Int), then the returned key is the actual stored key rather than k. Time: O(c log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.isequal-Tuple{SortedDict,SortedDict}",
    "page": "Sorted Containers",
    "title": "Base.isequal",
    "category": "method",
    "text": "isequal(sc1,sc2)\n\nChecks if two containers are equal in the sense that they contain the same items; the keys are compared using the eq method, while the values are compared with the isequal function. In the case of SortedMultiDict, equality requires that the values associated with a particular key have same order (that is, the same insertion order). Note that isequal in this sense does not imply any correspondence between semitokens for items in sc1 with those for sc2. If the equality-testing method associated with the keys and values implies hash-equivalence in the case of SortedDict, then isequal of the entire containers implies hash-equivalence of the containers. Time: O(cn + n log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.packcopy-Tuple{SortedDict}",
    "page": "Sorted Containers",
    "title": "DataStructures.packcopy",
    "category": "method",
    "text": "packcopy(sc)\n\nThis returns a copy of sc in which the data is packed. When deletions take place, the previously allocated memory is not returned. This function can be used to reclaim memory after many deletions. Time: O(cn log n)\n\n\n\n\n\npackcopy(sc)\n\nThis returns a copy of sc in which the data is packed. When deletions take place, the previously allocated memory is not returned. This function can be used to reclaim memory after many deletions. Time: O(cn log n)\n\n\n\n\n\npackcopy(sc)\n\nThis returns a copy of sc in which the data is packed. When deletions take place, the previously allocated memory is not returned. This function can be used to reclaim memory after many deletions. Time: O(cn log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#DataStructures.packdeepcopy-Tuple{Any}",
    "page": "Sorted Containers",
    "title": "DataStructures.packdeepcopy",
    "category": "method",
    "text": "packdeepcopy(sc)\n\nThis returns a packed copy of sc in which the keys and values are deep-copied. This function can be used to reclaim memory after many deletions. Time: O(cn log n)\n\n\n\n\n\npackdeepcopy(sc)\n\nThis returns a packed copy of sc in which the keys and values are deep-copied. This function can be used to reclaim memory after many deletions. Time: O(cn log n)\n\n\n\n\n\npackdeepcopy(sc)\n\nThis returns a packed copy of sc in which the keys and values are deep-copied. This function can be used to reclaim memory after many deletions. Time: O(cn log n)\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.merge-Union{Tuple{Ord}, Tuple{D}, Tuple{K}, Tuple{SortedDict{K,D,Ord},Vararg{AbstractDict{K,D},N} where N}} where Ord<:Base.Order.Ordering where D where K",
    "page": "Sorted Containers",
    "title": "Base.merge",
    "category": "method",
    "text": "merge(sc1, sc2...)\n\nThis returns a SortedDict or SortedMultiDict that results from merging SortedDicts or SortedMultiDicts sc1, sc2, etc., which all must have the same key-value-ordering types. In the case of keys duplicated among the arguments, the rightmost argument that owns the key gets its value stored for SortedDict. In the case of SortedMultiDict all the key-value pairs are stored, and for keys shared between sc1 and sc2 the ordering is left-to-right. This function is not available for SortedSet, but the union function (see below) provides equivalent functionality. Time: O(cN log N), where N is the total size of all the arguments.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.merge!-Union{Tuple{Ord}, Tuple{D}, Tuple{K}, Tuple{SortedDict{K,D,Ord},Vararg{AbstractDict{K,D},N} where N}} where Ord<:Base.Order.Ordering where D where K",
    "page": "Sorted Containers",
    "title": "Base.merge!",
    "category": "method",
    "text": "merge!(sc, sc1...)\n\nThis updates sc by merging SortedDicts or SortedMultiDicts sc1, etc. into sc. These must all must have the same key-value types. In the case of keys duplicated among the arguments, the rightmost argument that owns the key gets its value stored for SortedDict. In the case of SortedMultiDict all the key-value pairs are stored, and for overlapping keys the ordering is left-to-right. This function is not available for SortedSet, but the union! function (see below) provides equivalent functionality. Time: O(cN log N), where N is the total size of all the arguments.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Other-Functions-1",
    "page": "Sorted Containers",
    "title": "Other Functions",
    "category": "section",
    "text": "isempty(sc)Returns true if the container is empty (no items). Time: O(1)length(sc)Returns the length, i.e., number of items, in the container. Time: O(1)in(pr::Pair, m::SortedDict{K,D,Ord}) where {K,D,Ord <: Ordering}in(x, iter)Returns true if x is in iter, where iter refers to any of the iterable objects described above in the discussion of container loops and x is of the appropriate type. For all of the iterables except the five listed below, the algorithm used is a linear-time search. For example, the call:(k=>v) in exclusive(sd, st1, st2)where sd is a SortedDict, st1 and st2 are semitokens, k is a key, and v is a value, will loop over all entries in the dictionary between the two tokens and a compare for equality using isequal between the indexed item and k=>v.The five exceptions are:(k=>v) in sd\n(k=>v) in smd\nk in ss\nk in keys(sd)\nk in keys(smd)Here, sd is a SortedDict, smd is a SortedMultiDict, and ss is a SortedSet.These five invocations of in use the index structure of the sorted container and test equality based on the order object of the keys rather than isequal. Therefore, these five are all faster than linear-time looping. The first three were already discussed in the previous entry. The last two are equivalent to haskey(sd,k) and haskey(smd,k) respectively. To force the use of isequal test on the keys rather than the order object (thus slowing the execution from logarithmic to linear time), replace the above five constructs with these:(k=>v) in collect(sd)\n(k=>v) in collect(smd)\nk in collect(ss)\nk in collect(keys(sd))\nk in collect(keys(smd))eltype(sc::SortedDict)keytype(sc::SortedDict)valtype(sc::SortedDict)ordtype(sc::SortedDict)similar(sc::SortedDict)orderobject(sc::SortedDict)haskey(sc::SortedDict,k)get(sd::SortedDict,k,v)get!(sd::SortedDict,k,v)getkey(sd::SortedDict,k,defaultk)isequal(sc1::SortedDict,sc2::SortedDict)packcopy(sc::SortedDict)deepcopy(sc)This returns a copy of sc in which the data is deep-copied, i.e., the keys and values are replicated if they are mutable types. A semitoken for the original sc is a valid semitoken for the copy because this operation preserves the relative positions of the data in memory. Time O(maxn), where maxn denotes the maximum size that sc has attained in the past.packdeepcopy(sc)merge(m::SortedDict{K,D,Ord},\n               others::AbstractDict{K,D}...) where {K,D,Ord <: Ordering}merge!(m::SortedDict{K,D,Ord},\n                others::AbstractDict{K,D}...) where {K,D,Ord <: Ordering}"
},

{
    "location": "sorted_containers.html#Base.union!-Tuple{SortedSet,Any}",
    "page": "Sorted Containers",
    "title": "Base.union!",
    "category": "method",
    "text": "union!(ss, iterable)\n\nThis function inserts each item from the second argument (which must iterable) into the SortedSet ss. The items must be convertible to the key-type of ss. Time: O(ci log n) where i is the number of items in the iterable argument.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.union-Tuple{SortedSet,Vararg{Any,N} where N}",
    "page": "Sorted Containers",
    "title": "Base.union",
    "category": "method",
    "text": "union(ss, iterable...)\n\nThis function creates a new SortedSet (the return argument) and inserts each item from ss and each item from each iterable argument into the returned SortedSet. Time: O(cn log n) where n is the total number of items in all the arguments.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.intersect-Union{Tuple{Ord}, Tuple{K}, Tuple{SortedSet{K,Ord},Vararg{SortedSet{K,Ord},N} where N}} where Ord<:Base.Order.Ordering where K",
    "page": "Sorted Containers",
    "title": "Base.intersect",
    "category": "method",
    "text": "intersect(ss, others...)\n\nEach argument is a SortedSet with the same key and order type. The return variable is a new SortedSet that is the intersection of all the sets that are input. Time: O(cn log n), where n is the total number of items in all the arguments.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.symdiff-Union{Tuple{Ord}, Tuple{K}, Tuple{SortedSet{K,Ord},SortedSet{K,Ord}}} where Ord<:Base.Order.Ordering where K",
    "page": "Sorted Containers",
    "title": "Base.symdiff",
    "category": "method",
    "text": "symdiff(ss1, ss2)\n\nThe two argument are sorted sets with the same key and order type. This operation computes the symmetric difference, i.e., a sorted set containing entries that are in one of ss1, ss2 but not both. Time: O(cn log n), where n is the total size of the two containers.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.setdiff-Union{Tuple{Ord}, Tuple{K}, Tuple{SortedSet{K,Ord},SortedSet{K,Ord}}} where Ord<:Base.Order.Ordering where K",
    "page": "Sorted Containers",
    "title": "Base.setdiff",
    "category": "method",
    "text": "setdiff(ss1, ss2)\n\nThe two arguments are sorted sets with the same key and order type. This operation computes the difference, i.e., a sorted set containing entries that in are in ss1 but not ss2. Time: O(cn log n), where n is the total size of the two containers.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.setdiff!-Tuple{SortedSet,Any}",
    "page": "Sorted Containers",
    "title": "Base.setdiff!",
    "category": "method",
    "text": "setdiff!(ss, iterable)\n\nThis function deletes items in ss that appear in the second argument. The second argument must be iterable and its entries must be convertible to the key type of m1. Time: O(cm log n), where n is the size of ss and m is the number of items in iterable.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Base.issubset-Tuple{Any,SortedSet}",
    "page": "Sorted Containers",
    "title": "Base.issubset",
    "category": "method",
    "text": "issubset(iterable, ss)\n\nThis function checks whether each item of the first argument is an element of the SortedSet ss. The entries must be convertible to the key-type of ss. Time: O(cm log n), where n is the sizes of ss and m is the number of items in iterable.\n\n\n\n\n\n"
},

{
    "location": "sorted_containers.html#Set-operations-1",
    "page": "Sorted Containers",
    "title": "Set operations",
    "category": "section",
    "text": "The SortedSet container supports the following set operations. Note that in the case of intersect, symdiff and setdiff, the two SortedSets should have the same key and ordering object. If they have different key or ordering types, no error message is produced; instead, the built-in default versions of these functions (that can be applied to Any iterables and that return arrays) are invoked.union!(m1::SortedSet, iterable_item)union(m1::SortedSet, others...)intersect(m1::SortedSet{K,Ord}, others::SortedSet{K,Ord}...) where {K, Ord <: Ordering}symdiff(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord}) where {K, Ord <: Ordering}setdiff(m1::SortedSet{K,Ord}, m2::SortedSet{K,Ord}) where {K, Ord <: Ordering}setdiff!(m1::SortedSet, iterable)issubset(iterable, m2::SortedSet)"
},

{
    "location": "sorted_containers.html#Ordering-of-keys-1",
    "page": "Sorted Containers",
    "title": "Ordering of keys",
    "category": "section",
    "text": "As mentioned earlier, the default ordering of keys uses isless and isequal functions. If the default ordering is used, it is a requirement of the container that isequal(a,b) is true if and only if !isless(a,b) and !isless(b,a) are both true. This relationship between isequal and isless holds for common built-in types, but it may not hold for all types, especially user-defined types. If it does not hold for a certain type, then a custom ordering argument must be defined as discussed in the next few paragraphs.The name for the default ordering (i.e., using isless and isequal) is Forward. Note: this is the name of the ordering object; its type is ForwardOrdering. Another possible ordering object is Reverse, which reverses the usual sorted order. This name must be imported import Base.Reverse if it is used.As an example of a custom ordering, suppose the keys are of type String, and the user wishes to order the keys ignoring case: APPLE, berry and Cherry would appear in that order, and APPLE and aPPlE would be indistinguishable in this ordering.The simplest approach is to define an ordering object of the form Lt(my_isless), where Lt is a built-in type (see ordering.jl) and my_isless is the user\'s comparison function. In the above example, the ordering object would be:Lt((x,y) -> isless(lowercase(x),lowercase(y)))The ordering object is indicated in the above list of constructors in the o position (see above for constructor syntax).This approach suffers from a performance hit (10%-50% depending on the container) because the compiler cannot inline or compute the correct dispatch for the function in parentheses, so the dispatch takes place at run-time. A more complicated but higher-performance method to implement a custom ordering is as follows. First, the user creates a singleton type that is a subtype of Ordering as follows:struct CaseInsensitive <: Ordering\nendNext, the user defines a method named lt for less-than in this ordering:lt(::CaseInsensitive, a, b) = isless(lowercase(a), lowercase(b))The first argument to lt is an object of the CaseInsensitive type (there is only one such object since it is a singleton type). The container also needs an equal-to function; the default is:eq(o::Ordering, a, b) = !lt(o, a, b) && !lt(o, b, a)For a further slight performance boost, the user can also customize this function with a more efficient implementation. In the above example, an appropriate customization would be:eq(::CaseInsensitive, a, b) = isequal(lowercase(a), lowercase(b))Finally, the user specifies the unique element of CaseInsensitive, namely the object CaseInsensitive(), as the ordering object to the SortedDict, SortedMultiDict or SortedSet constructor.For the above code to work, the module must make the following declarations, typically near the beginning:import Base.Ordering\nimport Base.lt\nimport DataStructures.eq"
},

{
    "location": "sorted_containers.html#Cautionary-note-on-mutable-keys-1",
    "page": "Sorted Containers",
    "title": "Cautionary note on mutable keys",
    "category": "section",
    "text": "As with ordinary Dicts, keys for the sorted containers can be either mutable or immutable. In the case of mutable keys, it is important that the keys not be mutated once they are in the container else the indexing structure will be corrupted. (The same restriction applies to Dict.) For example, suppose a SortedDict sd is defined in which the keys are of type Array{Int,1}. (For this to be possible, the user must provide an isless function or order object for Array{Int,1} since none is built into Julia.) Suppose the values of sd are of type Int. Then the following sequence of statements leaves sd in a corrupted state:k = [1,2,3]\nsd[k] = 19\nk[1] = 7"
},

{
    "location": "sorted_containers.html#Performance-of-Sorted-Containers-1",
    "page": "Sorted Containers",
    "title": "Performance of Sorted Containers",
    "category": "section",
    "text": "The sorted containers are currently not optimized for cache performance. This will be addressed in the future.There is a minor performance issue as follows: the container may hold onto a small number of keys and values even after the data records containing those keys and values have been deleted. This may cause a memory drain in the case of large keys and values. It may also lead to a delay in the invocation of finalizers. All keys and values are released completely by the empty! function."
},

]}
