# Block-based dequeue

type DequeBlock{T}
    data::Vector{T}  # only data[front:back] is valid
    capa::Int   
    front::Int
    back::Int
    prev::Union(Nothing, DequeBlock{T})  # ref to previous block
    next::Union(Nothing, DequeBlock{T})  # ref to next block
end

capacity(blk::DequeBlock) = length(blk.data)
length(blk::DequeBlock) = blk.back - blk.front + 1
isempty(blk::DequeBlock) = blk.back < blk.front

function rear_deque_block{T}(ty::Type{T}, n::Int)
    data = Array(T, n)
    DequeBlock{T}(data, n, 1, 0, nothing, nothing)
end

function head_deque_block{T}(ty::Type{T}, n::Int)
    data = Array(T, n)
    DequeBlock{T}(data, n, n+1, n, nothing, nothing)
end

const default_dequeue_blocksize = 2048

type Deque{T}
    nblocks::Int
    blksize::Int
    len::Int
    head::DequeBlock{T}
    rear::DequeBlock{T}
    
    function Deque(blksize::Int)
        head = rear = rear_deque_block(T, blksize)
        new(1, blksize, 0, head, rear)
    end
    
    Deque() = Deque{T}(default_dequeue_blocksize::Int)
end

isempty(q::Deque) = q.len == 0
length(q::Deque) = q.len

block_size(q::Deque) = q.blksize
num_blocks(q::Deque) = q.nblocks

front(q::Deque) = q.head.data[q.head.front]
back(q::Deque) = q.rear.data[q.rear.back]

function dump(io::IO, q::Deque)
    println(io, "Deque (length = $(q.len), blksize = $(q.blksize), nblocks = $(q.nblocks))")
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


function empty!{T}(q::Deque{T})
    # release all blocks except the head
    if q.nblocks > 1
        cb::DequeBlock{T} = q.rear
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


function push!{T}(q::Deque{T}, x::T)  # push back
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
    q
end

function unshift!{T}(q::Deque{T}, x::T)   # push front
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
    q
end

function pop!{T}(q::Deque{T})   # pop back
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
            q.rear = rear.prev::DequeBlock{T}
            q.rear.next = nothing
            q.nblocks -= 1
        end        
    end 
    q.len -= 1
    x
end


function shift!{T}(q::Deque{T})  # pop front
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
            q.head = head.next::DequeBlock{T}
            q.head.prev = nothing
            q.nblocks -= 1
        end
    end
    q.len -= 1
    x
end


# dequeue iteration

immutable DequeIterator{T}
    is_done::Bool
    cblock::DequeBlock{T}  # current block
    i::Int
end

start{T}(q::Deque{T}) = DequeIterator{T}(isempty(q), q.head, q.head.front)

function next{T}(q::Deque{T}, s::DequeIterator{T})
    cb::DequeBlock{T} = s.cblock
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
    
    (x, DequeIterator{T}(is_done, cb, i))
end

done{T}(q::Deque{T}, s::DequeIterator{T}) = s.is_done

