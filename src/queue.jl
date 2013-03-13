# FIFO queue

type Queue{T}
    q::Dequeue{T}
    
    Queue() = new(Dequeue{T}())
    Queue(blksize::Int) = new(Dequeue{T}(blksize))
end

isempty(s::Queue) = isempty(s.q)
length(s::Queue) = length(s.q)

front(s::Queue) = front(s.q)
back(s::Queue) = back(s.q)

enqueue!{T}(s::Queue{T}, x::T) = push_back!(s.q, x)
dequeue!{T}(s::Queue{T}) = pop_front!(s.q)
