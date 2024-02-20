module DataStructures

    using Base: Iterators, HasEltype, HasLength, IteratorEltype, IteratorSize, SizeUnknown,
                lt, Ordering, ForwardOrdering, Forward, ReverseOrdering, Reverse, Lt,
                isbitsunion, isiterable, dict_with_eltype, KeySet, Callable, _tablesz,
                findnextnot, unsafe_getindex, unsafe_setindex!, peek


    using Compat # Provides Base.Order.ReverseOrdering(). May remove this line with julia 1.4
    using OrderedCollections
    using OrderedCollections: isordered
    export OrderedDict, OrderedSet, LittleDict
    export DefaultDict, DefaultOrderedDict

    export complement, complement!

    export Deque, Stack, Queue, CircularDeque
    export enqueue!, dequeue!, dequeue_pair!, update!
    export capacity, num_blocks, top_with_handle, sizehint!

    export Accumulator, counter, reset!, inc!, dec!
    export IntDisjointSets, DisjointSets, num_groups, find_root!, in_same_set, root_union!
    export FenwickTree, length, inc!, dec!, incdec!, prefixsum

    export AbstractHeap, compare, extract_all!, extract_all_rev!
    export BinaryHeap, BinaryMinHeap, BinaryMaxHeap, nlargest, nsmallest
    export MutableBinaryHeap, MutableBinaryMinHeap, MutableBinaryMaxHeap
    export heapify!, heapify, heappop!, heappush!, isheap
    export BinaryMinMaxHeap, popmin!, popmax!, popall!

    export Trie, subtrie, keys_with_prefix, partial_path

    export LinkedList, Nil, Cons, nil, cons, head, tail, list, filter, cat,
           reverse
    export MutableLinkedList
    export SortedDict, SortedMultiDict, SortedSet
    export SDToken, SDSemiToken, SMDToken, SMDSemiToken
    export SetToken, SetSemiToken
    export startof
    export pastendsemitoken, beforestartsemitoken
    export searchsortedafter, searchequalrange
    export packcopy, packdeepcopy
    export exclusive, inclusive, semitokens
    export orderobject, ordtype, Lt, compare, onlysemitokens

    export MultiDict, enumerateall
    export RobinDict
    export OrderedRobinDict, isordered
    export SwissDict

    export DiBitVector

    export RBTree, search_node, minimum_node
    export SplayTree, maximum_node
    export AVLTree, sorted_rank
    export SplayTree, maximum_node

    export findkey

    include("delegate.jl")

    include("deque.jl")
    include("circ_deque.jl")
    include("stack.jl")
    include("queue.jl")
    include("accumulator.jl")
    include("disjoint_set.jl")
    include("heaps.jl")

    include("default_dict.jl")
    include("dict_support.jl")
    include("trie.jl")

    include("int_set.jl")

    include("fenwick.jl")

    include("list.jl")
    include("mutable_list.jl")
    include("balanced_tree.jl")
    include("tokens.jl")

    import .Tokens: IntSemiToken

    include("multi_dict.jl")
    include("sorted_dict.jl")
    include("sorted_multi_dict.jl")
    include("sorted_set.jl")
    include("tokens2.jl")
    include("container_loops.jl")
    include("robin_dict.jl")
    include("ordered_robin_dict.jl")
    include("swiss_dict.jl")
    export
        CircularBuffer,
        capacity,
        isfull
    include("circular_buffer.jl")

    export status
    export deref_key, deref_value, deref, advance, regress

    export PriorityQueue, peek

    include("priorityqueue.jl")
    include("sparse_int_set.jl")
    export SparseIntSet

    include("dibit_vector.jl")
    include("avl_tree.jl")
    include("red_black_tree.jl")
    include("splay_tree.jl")

    include("deprecations.jl")

    @static if VERSION <= v"1.3"
        _unsetindex!(a, i) = a
    else
        _unsetindex! = Base._unsetindex!
    end
end
