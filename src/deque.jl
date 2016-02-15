# Block-based deque
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
ishead(blk::DequeBlock) = is(blk.prev, blk)
isrear(blk::DequeBlock) = is(blk.next, blk)


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

"""
    deque(T)

Create a deque of type `T`.
"""
deque{T}(::Type{T}) = Deque{T}()

isempty(q::Deque) = q.len == 0
length(q::Deque) = q.len
num_blocks(q::Deque) = q.nblocks

"""
    front(q::Deque)

Returns the first element of the deque `q`.
"""
function front(q::Deque)
    isempty(q) && throw(ArgumentError("Deque must be non-empty"))
    blk = q.head
    blk.data[blk.front]
end

"""
    back(q::Deque)

Returns the last element of the deque `q`.
"""
function back(q::Deque)
    isempty(q) && throw(ArgumentError("Deque must be non-empty"))
    blk = q.rear
    blk.data[blk.back]
end


# Iteration

immutable DequeIterator{T}
    q::Deque
end

start{T}(qi::DequeIterator{T}) = (qi.q.head, qi.q.head.front)

function next{T}(qi::DequeIterator{T}, s)
    cb = s[1]
    i = s[2]
    x = cb.data[i]

    i += 1
    if i > cb.back && !isrear(cb)
        cb = cb.next
        i = 1
    end

    (x, (cb, i))
end

done{T}(q::DequeIterator{T}, s) = (s[2] > s[1].back)

# Backwards deque iteration

immutable ReverseDequeIterator{T}
    q::Deque
end

start{T}(qi::ReverseDequeIterator{T}) = (qi.q.rear, qi.q.rear.back)

# We're finished when our index is less than the first index
# of the current block (which can only happen on the first block)
done{T}(qi::ReverseDequeIterator{T}, s) = (s[2] < s[1].front)

function next{T}(qi::ReverseDequeIterator{T}, s)
    cb = s[1]
    i = s[2]
    x = cb.data[i]

    i -= 1
    # If we're past the beginning of a block, go to the previous one
    if i < cb.front && !ishead(cb)
        cb = cb.prev
        i = cb.back
    end

    (x, (cb, i))
end

reverse_iter{T}(q::Deque{T}) = ReverseDequeIterator{T}(q)

start{T}(q::Deque{T}) = start(DequeIterator{T}(q))
next{T}(q::Deque{T}, s) = next(DequeIterator{T}(q), s)
done{T}(q::Deque{T}, s) = done(DequeIterator{T}(q), s)

Base.length{T}(qi::DequeIterator{T}) = qi.q.len
Base.length{T}(qi::ReverseDequeIterator{T}) = qi.q.len

Base.collect{T}(q::Deque{T}) = T[x for x in q]

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
    q.rear = q.head
    q
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
    isempty(q) && throw(ArgumentError("Deque must be non-empty"))
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
    isempty(q) && throw(ArgumentError("Deque must be non-empty"))
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

const _deque_hashseed = UInt === UInt64 ? 0x950aa17a3246be82 : 0x4f26f881
function hash(x::Deque, h::UInt)
    h += _deque_hashseed
    for (i, x) in enumerate(x)
        h += i * hash(x)
    end
    h
end

function ==(x::Deque, y::Deque)
    length(x) != length(y) && return false
    for (i, j) in zip(x, y)
        i == j || return false
    end
    true
end
