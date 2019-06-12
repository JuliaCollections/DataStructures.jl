# stacks

mutable struct Stack{T}
    store::Deque{T}
end

Stack{T}() where {T} = Stack(Deque{T}())
@deprecate Stack(ty::Type{T}) where {T} Stack{T}()

Stack{T}(blksize::Integer) where {T} = Stack(Deque{T}(blksize))
@deprecate Stack(ty::Type{T}, blksize::Integer) where {T} Stack{T}(blksize::Integer)

isempty(s::Stack) = isempty(s.store)
length(s::Stack) = length(s.store)

top(s::Stack) = back(s.store)

function push!(s::Stack, x)
    push!(s.store, x)
    s
end

pop!(s::Stack) = pop!(s.store)

empty!(s::Stack) = (empty!(s.store); s)

iterate(st::Stack, s...) = iterate(reverse_iter(st.store), s...)

reverse_iter(s::Stack{T}) where {T} = DequeIterator{T}(s.store)

function show(io::IO, s::Stack)
    elem = collect(s)
    if VERSION < v"1.2-DEV"
        summary(io, s, axes(elem))
    else
        Base.array_summary(io, s, axes(elem))
    end
    isempty(s) && return
    println(io, ":")
    Base.print_array(io, elem)
end
