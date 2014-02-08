# Block-based dequeue

#######################################
#
#  DequeBlock
#
#######################################

type DequeBlock{T}
    data::Vector{T}  # only data[front:back] is valid
    capa::Int   
    front::Int
    back::Int
    prev::DequeBlock{T}  # ref to previous block
    next::DequeBlock{T}  # ref to next block

    function DequeBlock(capa::Int, front::Int)
        data = Array(T, capa)
        blk = new(data, capa, front, front-1)
        blk.prev = blk
        blk.next = blk
        blk
    end
end

# block at the rear of the chain, elements towards the front
rear_deque_block{T}(ty::Type{T}, n::Int) = DequeBlock{T}(n, 1)

# block at the head of the train, elements towards the back
head_deque_block{T}(ty::Type{T}, n::Int) = DequeBlock{T}(n, n+1)

capacity(blk::DequeBlock) = blk.capa
length(blk::DequeBlock) = blk.back - blk.front + 1
isempty(blk::DequeBlock) = blk.back < blk.front

# reset the block to empty, and position

function reset!{T}(blk::DequeBlock{T}, front::Int)
    blk.front = front
    blk.back = front - 1
    blk.prev = blk
    blk.next = blk
end

function show(io::IO, blk::DequeBlock)  # avoids recursion into prev and next
    x = blk.data[blk.front:blk.back]
    print(io, "$(typeof(blk))(capa = $(blk.capa), front = $(blk.front), back = $(blk.back)): $x")
end


#######################################
#
#  Deque
#
#######################################

const DEFAULT_DEQUEUE_BLOCKSIZE = 1024

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
    
    Deque() = Deque{T}(DEFAULT_DEQUEUE_BLOCKSIZE)
end

deque{T}(::Type{T}) = Deque{T}()

isempty(q::Deque) = q.len == 0
length(q::Deque) = q.len
num_blocks(q::Deque) = q.nblocks

function front(q::Deque)
    if isempty(q)
        throw(ArgumentError("Attempted to front at an empty dequeue."))
    end
    blk = q.head
    blk.data[blk.front]
end

function back(q::Deque)
    if isempty(q)
        throw(ArgumentError("Attempted to back at an empty dequeue."))
    end 
    blk = q.rear
    blk.data[blk.back]
end


# Iteration

immutable DequeIterator{T}
    is_done::Bool
    cblock::DequeBlock{T}  # current block
    i::Int
end

start{T}(q::Deque{T}) = DequeIterator{T}(isempty(q), q.head, q.head.front)

function next{T}(q::Deque{T}, s::DequeIterator{T})
    cb = s.cblock
    i::Int = s.i
    x::T = cb.data[i]
    
    is_done = false
    
    i += 1
    if i > cb.back
        cb_next = cb.next
        if is(cb, cb_next)
            is_done = true
        else
            cb = cb_next
            i = 1
        end
    end 
    
    (x, DequeIterator{T}(is_done, cb, i))
end

done{T}(q::Deque{T}, s::DequeIterator{T}) = s.is_done


function Base.collect{T}(q::Deque{T})
    r = T[]
    for x::T in q
        push!(r, x)
    end
    return r
end


# Showing

function show(io::IO, q::Deque)
    print(io, "Deque [$(collect(q))]")
end

function dump(io::IO, q::Deque)
    println(io, "Deque (length = $(q.len), nblocks = $(q.nblocks))")
    cb::DequeBlock = q.head
    i = 1
    while true
        print(io, "block $i [$(cb.front):$(cb.back)] ==> ")
        for j = cb.front : cb.back
            print(io, cb.data[j])
            print(io, ' ')
        end
        println(io)
        
        cb_next::DequeBlock = cb.next
        if !is(cb, cb_next)
            cb = cb_next            
            i += 1
        else
            break
        end
    end
end


# Manipulation

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
    reset!(q.head, 1)
    
    # reset queue fields
    q.nblocks = 1
    q.len = 0
    q.rear = h
end


function push!{T}(q::Deque{T}, x)  # push back
    rear = q.rear
    
    if isempty(rear)
        rear.front = 1
        rear.back = 0
    end
    
    if rear.back < rear.capa
        @inbounds rear.data[rear.back += 1] = convert(T, x)
    else
        new_rear = rear_deque_block(T, q.blksize)
        new_rear.back = 1
        new_rear.data[1] = convert(T, x)
        new_rear.prev = rear
        q.rear = rear.next = new_rear
        q.nblocks += 1 
    end
    q.len += 1
    q
end

function unshift!{T}(q::Deque{T}, x)   # push front
    head = q.head
    
    if isempty(head)
        n = head.capa
        head.front = n + 1
        head.back = n
    end
    
    if head.front > 1
        @inbounds head.data[head.front -= 1] = convert(T, x)
    else
        n::Int = q.blksize
        new_head = head_deque_block(T, n)
        new_head.front = n
        new_head.data[n] = convert(T, x)
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

    @inbounds x = rear.data[rear.back]
    rear.back -= 1
    if rear.back < rear.front
        if q.nblocks > 1
            # release and detach the rear block
            empty!(rear.data)
            q.rear = rear.prev::DequeBlock{T}
            q.rear.next = q.rear
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
    
    @inbounds x = head.data[head.front]
    head.front += 1
    if head.back < head.front
        if q.nblocks > 1
            # release and detach the head block
            empty!(head.data)
            q.head = head.next::DequeBlock{T}
            q.head.prev = q.head
            q.nblocks -= 1
        end
    end
    q.len -= 1
    x
end

