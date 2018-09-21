module DataStructures

    import Base: <, <=, ==, cat, copy, dump, eachindex, eltype, empty, first,
                 get, getindex, getkey, hash, haskey, in, intersect, isempty,
                 isequal, isless, issubset, iterate, keys, keytype, last,
                 lastindex, length, lt, map, merge, reverse, searchsortedfirst,
                 searchsortedlast, setdiff, show, similar, sum, symdiff, union,
                 valtype, values,

                 delete!, empty!, get!, insert!, merge!, pop!, popfirst!, push!,
                 pushfirst!, setindex!, sizehint!, union!,

                 Forward, ForwardOrdering, Lt, Ordering, Reverse,
                 ReverseOrdering

    using OrderedCollections
    import OrderedCollections: filter, filter!, isordered

    export complement, complement!

    export Deque, Stack, Queue, CircularDeque
    export deque, enqueue!, dequeue!, dequeue_pair!, update!, reverse_iter
    export capacity, num_blocks, front, back, top, top_with_handle, sizehint!

    export Accumulator, counter, reset!, inc!, dec!

    export ClassifiedCollections
    export classified_lists, classified_sets, classified_counters

    export IntDisjointSets, DisjointSets, num_groups, find_root, in_same_set, root_union!

    export AbstractHeap, compare, extract_all!
    export BinaryHeap, binary_minheap, binary_maxheap, nlargest, nsmallest
    export MutableBinaryHeap, mutable_binary_minheap, mutable_binary_maxheap
    export heapify!, heapify, heappop!, heappush!, isheap

    export OrderedDict, OrderedSet
    export DefaultDict, DefaultOrderedDict
    export Trie, subtrie, keys_with_prefix, path

    export LinkedList, Nil, Cons, nil, cons, head, tail, list, filter, cat,
           reverse
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

    export findkey

    include("delegate.jl")

    include("deque.jl")
    include("circ_deque.jl")
    include("stack.jl")
    include("queue.jl")
    include("accumulator.jl")
    include("classified_collections.jl")
    include("disjoint_set.jl")
    include("heaps.jl")

    include("default_dict.jl")
    include("dict_support.jl")
    include("trie.jl")

    include("int_set.jl")

    include("list.jl")
    include("balanced_tree.jl")
    include("tokens.jl")

    import .Tokens: IntSemiToken

    include("multi_dict.jl")
    include("sorted_dict.jl")
    include("sorted_multi_dict.jl")
    include("sorted_set.jl")
    include("tokens2.jl")
    include("container_loops.jl")

    export
        CircularBuffer,
        capacity,
        isfull
    include("circular_buffer.jl")

    export status
    export deref_key, deref_value, deref, advance, regress

    export PriorityQueue, peek

    include("priorityqueue.jl")
end
