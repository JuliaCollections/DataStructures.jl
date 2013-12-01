module DataStructures
    
    import Base: length, isempty, start, next, done,
                 show, dump, empty!, getindex, setindex!, get,
                 in, haskey, keys, merge, copy,
                 push!, pop!, shift!, unshift!, add!,
                 union!, delete!, similar, sizehint
    
    export Deque, Stack, Queue
    export deque, stack, queue, enqueue!, dequeue!, update!
    export capacity, num_blocks, front, back, top, sizehint

    export Accumulator, counter
    export ClassifiedCollections
    export classified_lists, classified_sets, classified_counters
    
    export IntDisjointSets, DisjointSets, num_groups, find_root, in_same_set

    export AbstractHeap, compare, extract_all!
    export BinaryHeap, binary_minheap, binary_maxheap
    export MutableBinaryHeap, mutable_binary_minheap, mutable_binary_maxheap

    export DefaultDict
    
    include("deque.jl") 
    include("stack.jl")   
    include("queue.jl")
    include("accumulator.jl")
    include("classifiedcollections.jl")
    include("disjoint_set.jl")
    include("heaps.jl")
    include("defaultdict.jl")
end
