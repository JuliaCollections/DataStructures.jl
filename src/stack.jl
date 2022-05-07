"""
    Stack{T}() where {T}
    Stack{T}(blksize::Integer) where {T}

Create a `Stack` object containing elements of type `T` for Last In, First Out (LIFO) access.

# Parameters
- `T::Type` Stack element data type.
- `blksize::Integer` Unrolled linked-list bleck size (in bytes). Defualt = 1024.

# Examples
```jldoctest
julia> s_int = Stack{Int64}() # create a stack with int elements
Stack{Int64}(Deque [Int64[]])

julia> s_float = Stack{Float64}() # create a stack with float elements
Stack{Float64}(Deque [Float64[]])
```
"""
mutable struct Stack{T}
    store::Deque{T}
end

Stack{T}() where {T} = Stack(Deque{T}())
Stack{T}(blksize::Integer) where {T} = Stack(Deque{T}(blksize))

"""
    isempty(s::Stack)

Check if stack `s` is empty.
"""
Base.isempty(s::Stack) = isempty(s.store)


"""
    isempty(s::Stack)

Return the number of elements in stack `s`.
"""
Base.length(s::Stack) = length(s.store)


"""
    eltype(::Type{Stack{T}}) where {T}

Return the type of the elements in the stack.
"""
Base.eltype(::Type{Stack{T}}) where {T}

"""
    first(s::Stack)

Get the top item from stack `s`. Also know as "peak".
"""
Base.first(s::Stack) = last(s.store)

Base.last(s::Stack) = first(s.store)

"""
    push!(s::Stack, x)

Insert new element `x` in top of stack `s`.
"""
function Base.push!(s::Stack, x)
    push!(s.store, x)
    return s
end

"""
   pop!(s::Stack) 

Remove and return the top element from stack `s`.
"""
Base.pop!(s::Stack) = pop!(s.store)

"""
    empty!(s::Stack)

Remove all elements from stack `s`.
"""
Base.empty!(s::Stack) = (empty!(s.store); s)

Base.iterate(st::Stack, s...) = iterate(Iterators.reverse(st.store), s...)

Iterators.reverse(s::Stack{T}) where {T} = DequeIterator{T}(s.store)

"""
    ==(x::Stack, y::Stack)

Check if stacks `x` and `y` are equal in term of their contents.
"""
Base.:(==)(x::Stack, y::Stack) = x.store == y.store
