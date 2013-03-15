module DataStructures
    
    import Base.length, Base.isempty, Base.start, Base.next, Base.done
    import Base.show, Base.dump, Base.empty!
    import Base.push!, Base.pop!
    
    export Dequeue, Stack, Queue

    export push_back!, push_front!, pop_back!, pop_front!, enqueue!, dequeue!
    export capacity, block_size, num_blocks, front, back, top
    
    include("dequeue.jl") 
    include("stack.jl")   
    include("queue.jl")
end
