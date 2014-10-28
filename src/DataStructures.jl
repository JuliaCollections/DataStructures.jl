module DataStructures

    import Base: length, isempty, start, next, done,
                 show, dump, empty!, getindex, setindex!, get, get!,
                 in, haskey, keys, merge, copy, cat,
                 push!, pop!, shift!, unshift!,
                 union!, delete!, similar, sizehint,
                 isequal, hash,
                 map, reverse

    export Deque, Stack, Queue
    export deque, enqueue!, dequeue!, update!
    export capacity, num_blocks, front, back, top, sizehint

    export Accumulator, counter
    export ClassifiedCollections
    export classified_lists, classified_sets, classified_counters

    export IntDisjointSets, DisjointSets, num_groups, find_root, in_same_set
    export push!

    export AbstractHeap, compare, extract_all!
    export BinaryHeap, binary_minheap, binary_maxheap
    export MutableBinaryHeap, mutable_binary_minheap, mutable_binary_maxheap

    export OrderedDict, OrderedSet
    export DefaultDict, DefaultOrderedDict
    export Trie, subtrie, keys_with_prefix, path

    export LinkedList, Nil, Cons, nil, cons, head, tail, list, filter, cat,
           reverse
    export SortedDict, SortedDictIndex, MultiMap, MultiMapIndex
    export ind_find, ind_insert!, delete_ind!, ind_first
    export is_ind_past_end, is_ind_before_start, past_end, before_start
    export advance_ind, regress_ind, deref_ind, deref_key_only_ind
    export ind_equal_or_greater, ind_greater, sorted_dict_range_iteration
    export multimap_range_iteration, ind_findrange, SortedSet, SortedSetIndex
    export sorted_set_range_iteration, enumerate_ind, packcopy, packdeepcopy





    include("delegate.jl")

    include("deque.jl")
    include("stack.jl")
    include("queue.jl")
    include("accumulator.jl")
    include("classifiedcollections.jl")
    include("disjoint_set.jl")
    include("heaps.jl")

    include("hashdict.jl")
    include("ordereddict.jl")
    include("orderedset.jl")
    include("defaultdict.jl")
    include("trie.jl")

    include("list.jl")
    include("balancedTree.jl")

    @deprecate stack Stack
    @deprecate queue Queue
    @deprecate add! push!
end
