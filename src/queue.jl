# FIFO queue

type Queue{T}
    store::Deque{T}
end

Queue{T}(ty::Type{T}) = Queue(Deque{T}())
Queue{T}(ty::Type{T}, blksize::Integer) = Queue(Deque{T}(blksize))

isempty(s::Queue) = isempty(s.store)
length(s::Queue) = length(s.store)

front(s::Queue) = front(s.store)
back(s::Queue) = back(s.store)

function enqueue!(s::Queue, x)
    push!(s.store, x)
    s
end

dequeue!(s::Queue) = shift!(s.store)

function iter{T}(q::Queue{T})
    a = T[]
    for i in q.store
        push!(a,i)
    end
    return a
end
