"""
    Stack{T}

a Stack for Last In First Out(LIFO) access

# Examples
```julia-repl
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
    top(s::Stack)

Get a top item from a stack
"""
top(s::Stack) = back(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    s
end

pop!(s::Stack) = pop!(s.store)

empty!(s::Stack) = (empty!(s.store); s)

"""
    iterate(s::Stack)

Get a LIFO iterator of a stack
"""
iterate(st::Stack, s...) = iterate(reverse_iter(st.store), s...)

"""
    reverse_iterate(s::Stack)

Get a FILO iterator of a stack
"""
reverse_iter(s::Stack{T}) where {T} = DequeIterator{T}(s.store)

==(x::Stack, y::Stack) = x.store == y.store
