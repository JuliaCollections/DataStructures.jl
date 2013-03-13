module SeqDataStructs
    
    import Base.length, Base.isempty, Base.start, Base.next, Base.done
    import Base.show, Base.dump, Base.empty!
    
    export Dequeue

    export push_back!, push_front!, pop_back!, pop_front!
    export capacity, block_size, num_blocks, front, back
    
    include("dequeue.jl")    
end
