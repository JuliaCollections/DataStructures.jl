"""
    Stack{T}() where {T}
    Stack{T}(blksize::Integer) where {T}

Create a `Stack` object containing elements of type `T` for **Last In, First Out**
(LIFO) access.

# Parameters
- `T::Type` Stack element data type.
- `blksize::Integer` Unrolled linked-list block size (in bytes) used in the
    underlying representation of the stack. Default = 1024. 

# Examples
```jldoctest
julia> s_int = Stack{Int64}() # create a stack with Int64 elements
Stack{Int64}(Deque [Int64[]])

julia> s_float = Stack{Float64}() # create a stack with Float64 elements
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

Returns `true` if stack `s` is empty - i.e. has no elements - or `false` otherwise.
"""
Base.isempty(s::Stack) = isempty(s.store)


"""
    length(s::Stack)

Return the number of elements in stack `s`.
"""
Base.length(s::Stack) = length(s.store)


"""
    eltype(::Type{Stack{T}}) where {T}

Return the type of the elements in the stack.
"""
Base.eltype(::Type{Stack{T}}) where {T} = T


"""
    first(s::Stack)

Get the first element of `s` in *Last In, First Out* order. Since `s` is a stack,
the first element will be the element at the top of `s` (also known as "peek" of
the stack).

# Example
```jldoctest
julia> s = Stack{Float32}()
Stack{Float32}(Deque [Float32[]])

julia> for i in range(1, 0.2, 5)
           push!(s, i)
       end

julia> s
Stack{Float32}(Deque [Float32[1.0, 0.8, 0.6, 0.4, 0.2]])

julia> first(s)
0.2f0
```
"""
Base.first(s::Stack) = last(s.store)

"""
    last(s::Stack)

Get the last element of `s` in *Last In, First Out*. Since `s` is a stack, the last
element will be the at bottom of the stack.

# Example
```jldoctest
julia> s = Stack{Float32}()
Stack{Float32}(Deque [Float32[]])

julia> for i in range(1, 0.2, 5)
           push!(s, i)
       end

julia> s
Stack{Float32}(Deque [Float32[1.0, 0.8, 0.6, 0.4, 0.2]])

julia> last(s)
1.0f0
```
"""
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

Make `s` empty by inplace-removing all its elements.
"""
Base.empty!(s::Stack) = (empty!(s.store); s)

Base.iterate(st::Stack, s...) = iterate(Iterators.reverse(st.store), s...)

Iterators.reverse(s::Stack{T}) where {T} = DequeIterator{T}(s.store)


"""
    ==(x::Stack, y::Stack)

Check if stacks `x` and `y` are equal in terms of their contents and the order in
which they are present in the stack. Internally calls `==()` for each of the pairs
formed by the elements of `x` and `y` in the order they appear in the stack.

# Example
```jldoctest
julia> s1, s2 = Stack{String}(), Stack{String}()
(Stack{String}(Deque [String[]]), Stack{String}(Deque [String[]]))

julia> for string in ["foo", "bar", "42"]
          push!(s1, string)
          push!(s2, string)
       end

julia> s1 == s2
true

julia> pop!(s1)
"42"

julia> s1 == s2
false
```
```jldoctest
julia> a, b = Stack{Int}(), Stack{Int}()
(Stack{Int64}(Deque [Int64[]]), Stack{Int64}(Deque [Int64[]]))

julia> for num in [1, 2, 3, 4] push!(a, num) end

julia> for num in [1, 2, 4, 3] push!(b, num) end

julia> a == b # same elements but in different order
false
```
"""
Base.:(==)(x::Stack, y::Stack) = x.store == y.store
