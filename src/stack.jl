"""
    Stack{T}() where {T}
    Stack{T}(blksize::Integer) where {T}

Create a `Stack` object containing elements of type `T` for Last In, First Out (LIFO) access.

# Parameters
- `T::Type` Stack element data type.
- `blksize::Integer` Unrolled linked-list bleck size (in bytes). Default = 1024.

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

# Example
```jldoctest
julia> s = Stack{Char}()
Stack{Char}(Deque [Char[]])

julia> isempty(s)
true

julia> for char in "racecar"
           push!(s, char)
       end

julia> isempty(s)
false
```
"""
Base.isempty(s::Stack) = isempty(s.store)


"""
    length(s::Stack)

Return the number of elements in stack `s`.

# Example
```jldoctest
julia> s = Stack{Char}()
Stack{Char}(Deque [Char[]])

julia> for char in "racecar"
           push!(s, char)
       end

julia> length(s)
7
```
"""
Base.length(s::Stack) = length(s.store)


"""
    eltype(::Type{Stack{T}}) where {T}

Return the type of the elements in the stack.

# Example
```jldoctest
julia> s = Stack{Float32}()
Stack{Float32}(Deque [Float32[]])

julia> eltype(s)
Float32

julia> eltype(s) <: Number
true
```
"""
Base.eltype(::Type{Stack{T}}) where {T} = T


"""
    first(s::Stack)

Get the first element of `s`. Since `s` is a stack, the first element will be the
element at the top of `s` (also known as "peek" of the stack).

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

Get the last element of `s`. Since `s` is a stack, the last element will be the at
bottom of the stack.

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
1.0f0
```
"""
Base.last(s::Stack) = first(s.store)


"""
    push!(s::Stack, x)

Insert new element `x` in top of stack `s`.

# Example
```jldoctest
julia> s = Stack{Int}()
Stack{Int64}(Deque [Int64[]])

julia> push!(s, 42)
Stack{Int64}(Deque [[42]])

julia> push!(s, 314)
Stack{Int64}(Deque [[42, 314]])
```
"""
function Base.push!(s::Stack, x)
    push!(s.store, x)
    return s
end


"""
    pop!(s::Stack) 

Remove and return the top element from stack `s`.

# Example
```jldoctest
julia> s = Stack{Int}()
Stack{Int64}(Deque [Int64[]])

julia> for i in 1:10
           push!(s, i)
       end

julia> s
Stack{Int64}(Deque [[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]])

julia> popped = pop!(s)
10

julia> s
Stack{Int64}(Deque [[1, 2, 3, 4, 5, 6, 7, 8, 9]])

julia> popped
10
```
"""
Base.pop!(s::Stack) = pop!(s.store)


"""
    empty!(s::Stack)

Make `s` empty by inplace-removing all its elements.

# Example
```jldoctest
julia> s = Stack{Int}()
Stack{Int64}(Deque [Int64[]])

julia> for i in 1:4
           push!(s, i)
       end

julia> isempty(s)
false

julia> empty!(s)
Stack{Int64}(Deque [Int64[]])

julia> isempty(s)
true
```
"""
Base.empty!(s::Stack) = (empty!(s.store); s)

Base.iterate(st::Stack, s...) = iterate(Iterators.reverse(st.store), s...)

Iterators.reverse(s::Stack{T}) where {T} = DequeIterator{T}(s.store)


"""
    ==(x::Stack, y::Stack)

Check if stacks `x` and `y` are equal in term of their contents. Internally calls `==()`
for each of the pairs formed by the elements of `x` and `y` in the order they appear
in the stack.

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
"""
Base.:(==)(x::Stack, y::Stack) = x.store == y.store
