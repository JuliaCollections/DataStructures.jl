module DataStructures
    
    import Base.length, Base.isempty, Base.start, Base.next, Base.done
    import Base.show, Base.dump, Base.empty!
    import Base.push!, Base.pop!, Base.shift!, Base.unshift!
    
    export Deque, Stack, Queue
    export stack, queue, enqueue!, dequeue!
    export capacity, block_size, num_blocks, front, back, top
    
    include("deque.jl") 
    include("stack.jl")   
    include("queue.jl")
end
