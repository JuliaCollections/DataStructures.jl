# Block-based dequeue

type DequeueBlock{T}
    data::Vector{T}  # only data[front:back] is valid
    capa::Int   
    front::Int
    back::Int
    prev::Union(Nothing, DequeueBlock{T})  # ref to previous block
    next::Union(Nothing, DequeueBlock{T})  # ref to next block
end

capacity(blk::DequeueBlock) = length(blk.data)
length(blk::DequeueBlock) = blk.back - blk.front + 1
isempty(blk::DequeueBlock) = blk.back < blk.front

function rear_deque_block{T}(ty::Type{T}, n::Int)
    data = Array(T, n)
    DequeueBlock{T}(data, n, 1, 0, nothing, nothing)
end

function head_deque_block{T}(ty::Type{T}, n::Int)
    data = Array(T, n)
    DequeueBlock{T}(data, n, n+1, n, nothing, nothing)
end

const default_dequeue_blocksize = 2048

type Dequeue{T}
    nblocks::Int
    blksize::Int
    len::Int
    head::DequeueBlock{T}
    rear::DequeueBlock{T}
    
    function Dequeue(blksize::Int)
        head = rear = rear_deque_block(T, blksize)
        new(1, blksize, 0, head, rear)
    end
    
    Dequeue() = Dequeue{T}(default_dequeue_blocksize::Int)
end

isempty(q::Dequeue) = q.len == 0
length(q::Dequeue) = q.len

block_size(q::Dequeue) = q.blksize
num_blocks(q::Dequeue) = q.nblocks

front(q::Dequeue) = q.head.data[q.head.front]
back(q::Dequeue) = q.rear.data[q.rear.back]

function dump(io::IO, q::Dequeue)
    println(io, "Dequeue (length = $(q.len), blksize = $(q.blksize), nblocks = $(q.nblocks))")
    cb = q.head
    i = 1
    while (cb != nothing)
        print(io, "block $i [$(cb.front):$(cb.back)] ==> ")
        for j = cb.front : cb.back
            print(io, string(cb.data[j]))
            print(io, "  ")
        end
        println(io, "")
        
        cb = cb.next
        i += 1
    end
end


function empty!{T}(q::Dequeue{T})
    # release all blocks except the head
    if q.nblocks > 1
        cb::DequeueBlock{T} = q.rear
        while cb != q.head
            empty!(cb.data)
            cb = cb.prev
        end
    end
    
    # clean the head block (but retain the block itself)
    h = q.head
    h.front = 1
    h.back = 0
    h.prev = nothing
    h.rear = nothing
    
    # reset queue fields
    q.nblocks = 1
    q.len = 0
    q.rear = h
end


function push_back!{T}(q::Dequeue{T}, x::T)
    rear = q.rear
    
    if isempty(rear)
        rear.front = 1
        rear.back = 0
    end
    
    if rear.back < rear.capa
        rear.data[rear.back += 1] = x
    else
        new_rear = rear_deque_block(T, q.blksize)
        new_rear.back = 1
        new_rear.data[1] = x
        new_rear.prev = rear
        q.rear = rear.next = new_rear
        q.nblocks += 1 
    end
    q.len += 1
end

function push_front!{T}(q::Dequeue{T}, x::T)
    head = q.head
    
    if isempty(head)
        n = head.capa
        head.front = n + 1
        head.back = n
    end
    
    if head.front > 1
        head.data[head.front -= 1] = x
    else
        n::Int = q.blksize
        new_head = head_deque_block(T, n)
        new_head.front = n
        new_head.data[n] = x
        new_head.next = head
        q.head = head.prev = new_head
        q.nblocks += 1
    end 
    q.len += 1
end

function pop_back!{T}(q::Dequeue{T})
    if isempty(q)
        throw(ArgumentError("Attempted to pop from an empty dequeue."))
    end
    
    rear = q.rear
    @assert rear.back >= rear.front

    x = rear.data[rear.back]
    rear.back -= 1
    if rear.back < rear.front
        if q.nblocks > 1
            # release and detach the rear block
            empty!(rear.data)
            q.rear = rear.prev::DequeueBlock{T}
            q.rear.next = nothing
            q.nblocks -= 1
        end        
    end 
    q.len -= 1
    x
end


function pop_front!{T}(q::Dequeue{T})
    if isempty(q)
        throw(ArgumentError("Attempted to pop from an empty dequeue."))
    end
    
    head = q.head
    @assert head.back >= head.front
    
    x = head.data[head.front]
    head.front += 1
    if head.back < head.front
        if q.nblocks > 1
            # release and detach the head block
            empty!(head.data)
            q.head = head.next::DequeueBlock{T}
            q.head.prev = nothing
            q.nblocks -= 1
        end
    end
    q.len -= 1
    x
end


# dequeue iteration

immutable DequeueIterator{T}
    is_done::Bool
    cblock::DequeueBlock{T}  # current block
    i::Int
end

start{T}(q::Dequeue{T}) = DequeueIterator{T}(isempty(q), q.head, q.head.front)

function next{T}(q::Dequeue{T}, s::DequeueIterator{T})
    cb::DequeueBlock{T} = s.cblock
    i::Int = s.i
    x = cb.data[i]
    
    is_done = false
    
    i += 1
    if i > cb.back
        if cb.next == nothing
            is_done = true
        else
            cb = cb.next
            i = 1
        end
    end 
    
    (x, DequeueIterator{T}(is_done, cb, i))
end

done{T}(q::Dequeue{T}, s::DequeueIterator{T}) = s.is_done

