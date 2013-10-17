module DataStructures
    
    import Base.length, Base.isempty, Base.start, Base.next, Base.done
    import Base.show, Base.dump, Base.empty!, Base.getindex
    import Base.haskey, Base.keys, Base.merge, Base.copy
    import Base.push!, Base.pop!, Base.shift!, Base.unshift!, Base.add!
    import Base.union!
    
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
    
    include("deque.jl") 
    include("stack.jl")   
    include("queue.jl")
    include("accumulator.jl")
    include("classifiedcollections.jl")
    include("disjoint_set.jl")
    include("heaps.jl")
end
