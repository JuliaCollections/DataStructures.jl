# Block-based deque
#######################################
#
#  DequeBlock
#
#######################################

mutable struct DequeBlock{T}
    data::Vector{T}  # only data[front:back] is valid
    capa::Int
    front::Int
    back::Int
    prev::DequeBlock{T}  # ref to previous block
    next::DequeBlock{T}  # ref to next block

    function DequeBlock{T}(capa::Int, front::Int) where T
        data = Vector{T}(undef, capa)
        blk = new{T}(data, capa, front, front-1)
        blk.prev = blk
        blk.next = blk
        return blk
    end

    # Convert any `Integer` to whatever `Int` is on the relevant machine
    DequeBlock{T}(capa::Integer, front::Integer) where T = DequeBlock{T}(Int(capa), Int(front))
end

# block at the rear of the chain, elements towards the front
rear_deque_block(ty::Type{T}, n::Integer) where {T} = DequeBlock{T}(n, 1)

# block at the head of the train, elements towards the back
head_deque_block(ty::Type{T}, n::Integer) where {T} = DequeBlock{T}(n, n+1)

capacity(blk::DequeBlock) = blk.capa
Base.length(blk::DequeBlock) = blk.back - blk.front + 1
Base.isempty(blk::DequeBlock) = blk.back < blk.front
ishead(blk::DequeBlock) = blk.prev === blk
isrear(blk::DequeBlock) =  blk.next === blk


# reset the block to empty, and position

function reset!(blk::DequeBlock{T}, front::Integer) where T
    empty!(blk.data)
    resize!(blk.data, blk.capa)
    blk.front = front
    blk.back = front - 1
    blk.prev = blk
    blk.next = blk
end

function Base.show(io::IO, blk::DequeBlock)  # avoids recursion into prev and next
    x = blk.data[blk.front:blk.back]
    print(io, "$(typeof(blk))(capa = $(blk.capa), front = $(blk.front), back = $(blk.back)): $x")
end


#######################################
#
#  Deque
#
#######################################

const DEFAULT_DEQUEUE_BLOCKSIZE = 1024

"""
    Deque{T}
    Deque{T}(blksize::Int) where T

Constructs `Deque` object for elements of type `T`.

Parameters
----------

`T::Type` Deque element data type.

`blksize::Int` Deque block size (in bytes). Default = 1024.
"""
mutable struct Deque{T}
    nblocks::Int
    blksize::Int
    len::Int
    head::DequeBlock{T}
    rear::DequeBlock{T}

    function Deque{T}(blksize::Integer) where T
        head = rear = rear_deque_block(T, blksize)
        new{T}(1, blksize, 0, head, rear)
    end

    Deque{T}() where {T} = Deque{T}(DEFAULT_DEQUEUE_BLOCKSIZE)
end

"""
    isempty(d::Deque)

Verifies if deque `d` is empty.
"""
Base.isempty(d::Deque) = d.len == 0

"""
    length(d::Deque) 

Returns the number of elements in deque `d`.
"""
Base.length(d::Deque) = d.len
num_blocks(d::Deque) = d.nblocks
Base.eltype(::Type{Deque{T}}) where T = T

"""
    first(d::Deque)

Returns the first element of the deque `d`.
"""
function Base.first(d::Deque)
    isempty(d) && throw(ArgumentError("Deque must be non-empty"))
    blk = d.head
    return blk.data[blk.front]
end

"""
    last(d::Deque)

Returns the last element of the deque `d`.
"""
function Base.last(d::Deque)
    isempty(d) && throw(ArgumentError("Deque must be non-empty"))
    blk = d.rear
    return blk.data[blk.back]
end


# Iteration

struct DequeIterator{T}
    d::Deque{T}
end

Base.last(di::DequeIterator) = last(di.d)

function Base.iterate(di::DequeIterator{T}, (cb, i) = (di.d.head, di.d.head.front)) where T
    i > cb.back && return nothing
    x = cb.data[i]

    i += 1
    if i > cb.back && !isrear(cb)
        cb = cb.next
        i = 1
    end

    return (x, (cb, i))
end

# Backwards deque iteration

function Base.iterate(di::Iterators.Reverse{<:Deque}, (cb, i) = (di.itr.rear, di.itr.rear.back))
    i < cb.front && return nothing
    x = cb.data[i]

    i -= 1
    # If we're past the beginning of a block, go to the previous one
    if i < cb.front && !ishead(cb)
        cb = cb.prev
        i = cb.back
    end

    return (x, (cb, i))
end

Base.iterate(d::Deque{T}, s...) where {T} = iterate(DequeIterator{T}(d), s...)

Base.length(di::DequeIterator{T}) where {T} = di.d.len

Base.collect(d::Deque{T}) where {T} = T[x for x in d]

# Showing

function Base.show(io::IO, d::Deque)
    print(io, "Deque [$(collect(d))]")
end

function Base.dump(io::IO, d::Deque)
    println(io, "Deque (length = $(d.len), nblocks = $(d.nblocks))")
    cb::DequeBlock = d.head
    i = 1
    while true
        print(io, "block $i [$(cb.front):$(cb.back)] ==> ")
        for j = cb.front : cb.back
            print(io, cb.data[j])
            print(io, ' ')
        end
        println(io)

        cb_next::DequeBlock = cb.next
        if cb !== cb_next
            cb = cb_next
            i += 1
        else
            break
        end
    end
end


# Manipulation

"""
    empty!(d::Deque{T}) where T

Reset the deque `d`.
"""
function Base.empty!(d::Deque{T}) where T
    # release all blocks except the head
    if d.nblocks > 1
        cb::DequeBlock{T} = d.rear
        while cb != d.head
            empty!(cb.data)
            cb = cb.prev
        end
    end

    # clean the head block (but retain the block itself)
    reset!(d.head, 1)

    # reset queue fields
    d.nblocks = 1
    d.len = 0
    d.rear = d.head
    return d
end


"""
    push!(d::Deque{T}, x) where T

Add an element to the back of deque `d`.
"""
function Base.push!(d::Deque{T}, x) where T
    rear = d.rear

    if isempty(rear)
        rear.front = 1
        rear.back = 0
    end

    if rear.back < rear.capa
        @inbounds rear.data[rear.back += 1] = convert(T, x)
    else
        new_rear = rear_deque_block(T, d.blksize)
        new_rear.back = 1
        new_rear.data[1] = convert(T, x)
        new_rear.prev = rear
        d.rear = rear.next = new_rear
        d.nblocks += 1
    end
    d.len += 1
    return d
end

"""
    pushfirst!(d::Deque{T}, x) where T

Add an element to the front of deque `d`.
"""
function Base.pushfirst!(d::Deque{T}, x) where T
    head = d.head

    if isempty(head)
        n = head.capa
        head.front = n + 1
        head.back = n
    end

    if head.front > 1
        @inbounds head.data[head.front -= 1] = convert(T, x)
    else
        n::Int = d.blksize
        new_head = head_deque_block(T, n)
        new_head.front = n
        new_head.data[n] = convert(T, x)
        new_head.next = head
        d.head = head.prev = new_head
        d.nblocks += 1
    end
    d.len += 1
    return d
end

"""
    pop!(d::Deque{T}) where T

Remove the element at the back of deque `d`.
"""
function Base.pop!(d::Deque{T}) where T
    isempty(d) && throw(ArgumentError("Deque must be non-empty"))
    rear = d.rear
    @assert rear.back >= rear.front

    @inbounds x = rear.data[rear.back]
    Base._unsetindex!(rear.data, rear.back) # see issue/884
    rear.back -= 1
    if rear.back < rear.front
        if d.nblocks > 1
            # release and detach the rear block
            empty!(rear.data)
            d.rear = rear.prev::DequeBlock{T}
            d.rear.next = d.rear
            d.nblocks -= 1
        end
    end
    d.len -= 1
    return x
end

"""
    popfirst!(d::Deque{T}) where T

Remove the element at the front of deque `d`.
"""
function Base.popfirst!(d::Deque{T}) where T
    isempty(d) && throw(ArgumentError("Deque must be non-empty"))
    head = d.head
    @assert head.back >= head.front

    @inbounds x = head.data[head.front]
    Base._unsetindex!(head.data, head.front) # see issue/884
    head.front += 1
    if head.back < head.front
        if d.nblocks > 1
            # release and detach the head block
            empty!(head.data)
            d.head = head.next::DequeBlock{T}
            d.head.prev = d.head
            d.nblocks -= 1
        end
    end
    d.len -= 1
    return x
end

const _deque_hashseed = UInt === UInt64 ? 0x950aa17a3246be82 : 0x4f26f881
function Base.hash(x::Deque, h::UInt)
    h += _deque_hashseed
    for (i, x) in enumerate(x)
        h += i * hash(x)
    end
    return h
end

"""
    ==(x::Deque, y::Deque)

Verify if the deques `x` and `y` are equal in terms of their contents.
"""
function Base.:(==)(x::Deque, y::Deque)
    length(x) != length(y) && return false
    for (i, j) in zip(x, y)
        i == j || return false
    end
    return true
end
