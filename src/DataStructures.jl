module DataStructures
    
    import Base.length, Base.isempty, Base.start, Base.next, Base.done
    import Base.show, Base.dump, Base.empty!
    import Base.push!, Base.pop!, Base.shift!, Base.unshift!, Base.add!
    import Base.union!
    
    export Deque, Stack, Queue
    export stack, queue, enqueue!, dequeue!, update!
    export capacity, num_blocks, front, back, top, sizehint
    
    export IntDisjointSets, DisjointSets, num_groups, find_root, in_same_set
    
    export AbstractHeap, compare, extract_all!
    export BinaryHeap, binary_minheap, binary_maxheap
    export MutableBinaryHeap, mutable_binary_minheap, mutable_binary_maxheap
    
    include("deque.jl") 
    include("stack.jl")   
    include("queue.jl")
    include("disjoint_set.jl")
    include("heaps.jl")
end
