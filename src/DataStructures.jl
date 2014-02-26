module DataStructures
    
    import Base: length, isempty, start, next, done,
                 show, dump, empty!, getindex, setindex!, get, get!,
                 in, haskey, keys, merge, copy,
                 push!, pop!, shift!, unshift!, add!,
                 union!, delete!, similar, sizehint, 
                 isequal, hash
    
    export Deque, Stack, Queue
    export deque, enqueue!, dequeue!, update!
    export capacity, num_blocks, front, back, top, sizehint

    export Accumulator, counter
    export ClassifiedCollections
    export classified_lists, classified_sets, classified_counters
    
    export IntDisjointSets, DisjointSets, num_groups, find_root, in_same_set

    export AbstractHeap, compare, extract_all!
    export BinaryHeap, binary_minheap, binary_maxheap
    export MutableBinaryHeap, mutable_binary_minheap, mutable_binary_maxheap

    export OrderedDict, OrderedSet
    export DefaultDict, DefaultOrderedDict
    
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

    @deprecate stack Stack
    @deprecate queue Queue
end
