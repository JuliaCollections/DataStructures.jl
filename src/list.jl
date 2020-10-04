abstract type LinkedList{T} end

Base.eltype(::Type{<:LinkedList{T}}) where T = T

mutable struct Nil{T} <: LinkedList{T}
end

mutable struct Cons{T} <: LinkedList{T}
    head::T
    tail::LinkedList{T}
end

cons(h, t::LinkedList{T}) where {T} = Cons{T}(h, t)

nil(T) = Nil{T}()
nil() = nil(Any)

head(x::Cons) = x.head
tail(x::Cons) = x.tail

Base.:(==)(x::Nil, y::Nil) = true
function Base.:(==)(x::Cons, y::Cons) 
    while true
        x.head == y.head || return false
        x = tail(x)
        y = tail(y)
        (x isa Nil || y isa Nil) && break
    end
    x == y
end

function Base.show(io::IO, l::LinkedList{T}) where T
    if isa(l,Nil)
        if T === Any
            print(io, "nil()")
        else
            print(io, "nil(", T, ")")
        end
    else
        print(io, "list(")
        show(io, head(l))
        for t in tail(l)
            print(io, ", ")
            show(io, t)
        end
        print(io, ")")
    end
end

list() = nil()

function list(elts...)
    l = nil()
    for i=length(elts):-1:1
        l = cons(elts[i],l)
    end
    return l
end

function list(elts::T...) where T
    l = nil(T)
    for i=length(elts):-1:1
        l = cons(elts[i],l)
    end
    return l
end

Base.length(l::Nil) = 0

function Base.length(l::Cons)
    n = 0
    for i in l
        n += 1
    end
    return n
end

function Base.map(f::Base.Callable, l::Nil{T}) where T
    if f isa Function
        nil(Core.Compiler.return_type(f, (T,)))
    else
        nil(f)
    end
end

function Base.map(f::Base.Callable, l::Cons{T}) where T
    first = f(l.head)
    n = nil(typeof(first) <: T ? T : typeof(first))
    root = l2 = cons(first, n)
    for h in tail(l)
        l2 = l2.tail = cons(f(h), n)
    end
    root
end

Base.filter(f::Function, l::Nil) = l

function Base.filter(f::Function, l::LinkedList{T}) where T
    n = nil(T)
    guard = l2 = cons(head(l), n)
    for h in l
        if f(h)
            l2 = l2.tail = cons(h, n)
        end
    end
    guard.tail
end

function Base.reverse(l::LinkedList{T}) where T
    l2 = nil(T)
    for h in l
        l2 = cons(h, l2)
    end
    return l2
end

Base.copy(l::Nil) = l

function Base.copy(l::Cons{T}) where T
    n = nil(T)
    root = l2 = cons(head(l), n)
    for h in l.tail
        l2 = l2.tail = cons(h, n)
    end
    root
end

Base.cat(lst::LinkedList) = lst

function Base.cat(lst::LinkedList, lsts::LinkedList...)
    T = typeof(lst).parameters[1]
    n = length(lsts)
    for i = 1:n
        T2 = typeof(lsts[i]).parameters[1]
        T = typejoin(T, T2)
    end

    l2 = nil(T)
    for h in lst
        l2 = cons(h, l2)
    end

    for i = 1:n
        for h in lsts[i]
            l2 = cons(h, l2)
        end
    end

    reverse(l2)
end

Base.iterate(l::LinkedList, ::Nil) = nothing
function Base.iterate(l::LinkedList, state::Cons = l)
    state.head, state.tail
end
