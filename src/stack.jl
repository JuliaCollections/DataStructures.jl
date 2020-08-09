"""
    Stack{T}([blksize::Integer=1024])

Create a `Stack` object containing elements of type `T` for Last In First Out (LIFO) access.

# Examples
```jldoctest
julia> s = Stack{Int}() # create a stack
Stack{Int64}(Deque [Int64[]])

julia> push!(s, 1) # push back a item
Stack{Int64}(Deque [[1]])

julia> x = top(s) # get a first item
1

julia> length(s)
1

julia> x = pop!(s) # get and remove a first item
1

julia> length(s)
0
```
"""
mutable struct Stack{T}
    store::Deque{T}
end

Stack{T}() where {T} = Stack(Deque{T}())
Stack{T}(blksize::Integer) where {T} = Stack(Deque{T}(blksize))

isempty(s::Stack) = isempty(s.store)
length(s::Stack) = length(s.store)
Base.eltype(::Type{Stack{T}}) where T = T

"""
    first(s::Stack)

Get the top item from the stack. Sometimes called peek.

Throws an `ArgumentError` if the stack is empty. This check
can be disabled with `@inbounds`.
"""
Base.@propagate_inbounds first(s::Stack) = last(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    return s
end

"""
    pop!(s::Stack)

Remove the top item from the stack and return it.

Throws an `ArgumentError` if the stack is empty. This check
can be disabled with `@inbounds`.
"""
Base.@propagate_inbounds pop!(s::Stack) = pop!(s.store)

empty!(s::Stack) = (empty!(s.store); s)

iterate(st::Stack, s...) = iterate(reverse_iter(st.store), s...)

"""
    reverse_iterate(s::Stack)

Get a FILO iterator of a stack
"""
reverse_iter(s::Stack{T}) where {T} = DequeIterator{T}(s.store)

==(x::Stack, y::Stack) = x.store == y.store
